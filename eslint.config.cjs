module.exports = [
  {
    ignores: [
      "**/node_modules/**",
      "**/build/**",
      "**/.dart_tool/**",
      "**/coverage/**",
      "android/**",
      "ios/**",
      "**/*.ts"
    ]
  },
  {
    files: ["**/*.js", "**/*.cjs", "**/*.mjs"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      parserOptions: {
        ecmaFeatures: {
          jsx: true
        }
      }
    },
    rules: {
      "no-unused-vars": "warn",
      "no-console": "off"
    }
  }
];
