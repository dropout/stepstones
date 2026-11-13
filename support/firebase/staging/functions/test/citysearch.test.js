/* eslint-disable @typescript-eslint/no-require-imports */
const {test, afterEach} = require("node:test");
const assert = require("node:assert/strict");
const {PlacesClient} = require("@googlemaps/places");
const citySearch = require("../lib/call/citysearch.f").default;

const originalKey = process.env.GOOGLE_MAPS_API_KEY;
process.env.GOOGLE_MAPS_API_KEY = "test-key";

afterEach(() => {
  if (originalKey === undefined) {
    delete process.env.GOOGLE_MAPS_API_KEY;
  } else {
    process.env.GOOGLE_MAPS_API_KEY = originalKey;
  }
});

test("returns valid results and legitimate empty results", async (t) => {
  process.env.GOOGLE_MAPS_API_KEY = "test-key";
  const autocomplete = t.mock.method(PlacesClient.prototype,
    "autocompletePlaces", async () => [{
      suggestions: [{
        placePrediction: {placeId: "id", text: {text: "Budapest"}},
      }],
    }]);
  assert.deepEqual(await citySearch.run({data: {queryString: " Bud "}}), {
    queryString: "Bud",
    results: [{placeId: "id", name: "Budapest", types: [], location: null}],
  });
  autocomplete.mock.mockImplementation(async () => [{}]);
  assert.deepEqual(await citySearch.run({data: {queryString: "Bud"}}), {
    queryString: "Bud", results: [],
  });
  assert.deepEqual(await citySearch.run({data: {queryString: " "}}), {
    queryString: "", results: [],
  });
});

test("rejects malformed inputs with an invalid argument error", async () => {
  await assert.rejects(citySearch.run({data: {queryString: 3}}),
    (error) => error.code === "invalid-argument");
});

test("reports provider and configuration errors safely", async (t) => {
  process.env.GOOGLE_MAPS_API_KEY = "test-key";
  t.mock.method(PlacesClient.prototype, "autocompletePlaces", async () => {
    throw new Error("invalid key: secret");
  });
  const isSafeError = (error) => error.code === "internal" &&
    error.message === "City search is unavailable";
  await assert.rejects(
    citySearch.run({data: {queryString: "Bud"}}), isSafeError);
  delete process.env.GOOGLE_MAPS_API_KEY;
  await assert.rejects(
    citySearch.run({data: {queryString: "Bud"}}), isSafeError);
});

test("rejects malformed responses and predictions", async (t) => {
  process.env.GOOGLE_MAPS_API_KEY = "test-key";
  const autocomplete = t.mock.method(PlacesClient.prototype,
    "autocompletePlaces", async () => []);
  const isInternal = (error) => error.code === "internal";
  await assert.rejects(
    citySearch.run({data: {queryString: "Bud"}}), isInternal);
  autocomplete.mock.mockImplementation(async () => [{suggestions: "invalid"}]);
  await assert.rejects(
    citySearch.run({data: {queryString: "Bud"}}), isInternal);
  autocomplete.mock.mockImplementation(async () => [{
    suggestions: [
      {placePrediction: {placeId: "id", text: {text: "Budapest"}}},
      {placePrediction: {text: {text: "Invalid"}}},
    ],
  }]);
  await assert.rejects(
    citySearch.run({data: {queryString: "Bud"}}), isInternal);
});
