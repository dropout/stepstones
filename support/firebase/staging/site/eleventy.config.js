// Builds the static legal and support pages into ../public for Firebase Hosting.
export default function (eleventyConfig) {
  eleventyConfig.addPassthroughCopy("style.css");
  eleventyConfig.ignores.add("README.md");
  eleventyConfig.addFilter("longDate", (d) =>
    new Date(d).toLocaleDateString("en-GB", {day: "numeric", month: "long", year: "numeric", timeZone: "UTC"}));
}

export const config = {
  dir: {input: ".", output: "../public"},
  markdownTemplateEngine: false,
};
