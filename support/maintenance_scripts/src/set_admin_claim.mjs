import admin from "firebase-admin";

const ADMIN_CLAIM = "admin";

function printUsageAndExit(message) {
	console.error(message);
	console.error(
		"Usage: node src/set_admin_claim.mjs --project=<firebase-project-id> (--email=<email>|--uid=<uid>) [--revoke] (--confirm|--dry-run)",
	);
	process.exit(1);
}

function parseCliArgs(argv) {
	const options = {
		project: "",
		email: "",
		uid: "",
		revoke: false,
		dryRun: false,
		confirm: false,
	};

	for (let index = 0; index < argv.length; index += 1) {
		const arg = argv[index];

		if (arg === "--dry-run") {
			options.dryRun = true;
			continue;
		}
		if (arg === "--confirm") {
			options.confirm = true;
			continue;
		}
		if (arg === "--revoke") {
			options.revoke = true;
			continue;
		}

		const readValue = (key) => {
			if (arg === `--${key}` && argv[index + 1]) {
				index += 1;
				return argv[index];
			}
			if (arg.startsWith(`--${key}=`)) {
				return arg.slice(`--${key}=`.length);
			}
			return null;
		};

		let matched = false;
		for (const key of ["project", "email", "uid"]) {
			const value = readValue(key);
			if (value !== null) {
				options[key] = value.trim();
				matched = true;
				break;
			}
		}
		if (!matched) {
			printUsageAndExit(`Unknown argument: ${arg}`);
		}
	}

	if (!options.confirm && !options.dryRun) {
		printUsageAndExit("Pass --confirm to write, or --dry-run to preview.");
	}
	if (options.confirm && options.dryRun) {
		printUsageAndExit("Use only one of --confirm or --dry-run.");
	}
	if (!options.project) {
		printUsageAndExit("Missing required argument: --project");
	}
	if (Boolean(options.email) === Boolean(options.uid)) {
		printUsageAndExit("Pass exactly one of --email or --uid.");
	}

	return options;
}

function initFirebase(projectId) {
	const serviceAccountEnv = process.env.FIREBASE_SERVICE_ACCOUNT;
	if (serviceAccountEnv) {
		const serviceAccount = JSON.parse(serviceAccountEnv);
		return admin.initializeApp({
			credential: admin.credential.cert({
				projectId: serviceAccount.project_id,
				clientEmail: serviceAccount.client_email,
				privateKey: serviceAccount.private_key.replace(/\\n/g, "\n"),
			}),
			projectId,
		});
	}

	// Use Application Default Credentials if service account JSON is not supplied.
	return admin.initializeApp({projectId});
}

async function main() {
	const options = parseCliArgs(process.argv.slice(2));
	const auth = admin.auth(initFirebase(options.project));

	const user = options.email ?
		await auth.getUserByEmail(options.email) :
		await auth.getUser(options.uid);

	// Other custom claims must survive because setCustomUserClaims replaces them all.
	const claims = {...(user.customClaims ?? {})};
	const wasAdmin = claims[ADMIN_CLAIM] === true;
	if (options.revoke) {
		delete claims[ADMIN_CLAIM];
	} else {
		claims[ADMIN_CLAIM] = true;
	}

	const action = options.revoke ? "revoke" : "grant";
	console.log(`Project: ${options.project}`);
	console.log(`User: ${user.uid} (${user.email ?? "no email"})`);
	console.log(`Currently admin: ${wasAdmin}`);

	if (options.dryRun) {
		console.log(`Dry-run: would ${action} the '${ADMIN_CLAIM}' claim.`);
		console.log(`Resulting claims: ${JSON.stringify(claims)}`);
		return;
	}

	await auth.setCustomUserClaims(user.uid, claims);
	console.log(`Done: ${action} '${ADMIN_CLAIM}' claim.`);
	console.log("The user must sign in again (or refresh the ID token) for it to take effect.");
}

main().catch((error) => {
	console.error("Failed to set admin claim");
	console.error(error);
	process.exit(1);
});
