import {HttpsError, onCall} from "firebase-functions/https";
import {logger} from "firebase-functions";
import {safeEnvVar} from "../util/safe_shit";
import {PlacesClient} from "@googlemaps/places";
import {CitySearchResponse, CitySearchResult} from "../models";
import {CitySearchResultSchema} from "../util/schema";
import {defineSecret} from "firebase-functions/params";

const googleMapsKeySecret = defineSecret("GOOGLE_MAPS_API_KEY");

// Search for cities using Google Maps Places Autocomplete API
export default onCall(
  {
    secrets: [googleMapsKeySecret],
  },
  async function citySearch(req) {
    const input: unknown = req.data?.queryString;
    if (input != null && typeof input !== "string") {
      throw new HttpsError("invalid-argument", "queryString must be a string");
    }
    const queryString = (input ?? "").trim();
    const results: Array<CitySearchResult> = [];

    if (!queryString) {
      return {queryString: "", results: []} as CitySearchResponse;
    }

    try {
      // Create PlacesClient
      const GOOGLE_MAPS_API_KEY = safeEnvVar("GOOGLE_MAPS_API_KEY");
      const placesClient = new PlacesClient({
        apiKey: GOOGLE_MAPS_API_KEY,
      });

      // Execute autocomplete request
      const autoCompleteResponse = await placesClient.autocompletePlaces({
        input: queryString,
        includedPrimaryTypes: ["locality"], // https://developers.google.com/maps/documentation/places/web-service/place-types

      });

      // Make sure we have suggestions
      // The response is an array, but we only care about the first item
      const result = Array.isArray(autoCompleteResponse) ?
        autoCompleteResponse[0] : undefined;
      if (!result || typeof result !== "object" || Array.isArray(result) ||
          (result.suggestions != null &&
          !Array.isArray(result.suggestions))) {
        throw new Error("Invalid Places autocomplete response");
      }
      const suggestions = result.suggestions ?? [];

      // Parse suggestions into CitySearchResult[]
      for (const suggestion of suggestions) {
        const prediction = suggestion.placePrediction;
        const rawCityResult: unknown = {
          placeId: prediction?.placeId,
          name: prediction?.text?.text ??
            prediction?.structuredFormat?.mainText?.text,
          types: prediction?.types ?? [],
          location: null,
        };
        const parsed = CitySearchResultSchema.safeParse(rawCityResult);

        if (!parsed.success) {
          logger.error("citySearch: Failed to parse placePrediction", {
            issues: parsed.error.issues,
          });
          throw new Error("Invalid Places autocomplete prediction");
        }

        // Collect parsed result
        const cityResult: CitySearchResult = parsed.data;
        results.push(cityResult);
      }
    } catch (error) {
      logger.error("citySearch: Error occurred", error);
      throw new HttpsError("internal", "City search is unavailable");
    }

    // Construct response
    const response: CitySearchResponse = {
      queryString,
      results,
    };
    return response;
  }
);
