module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
  ],
  parserOptions: {
    ecmaVersion: 2020,
  },
  rules: {
    "no-console": "off",
    "no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
    "quotes": ["error", "double"],
    "indent": ["error", 2],
    "max-len": ["error", { code: 120, ignoreStrings: true }],
  },
};
