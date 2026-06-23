# Context Collector Privacy Policy

_Last updated: 17 January 2025_

Context Collector is a desktop application that helps you assemble text from local files into a single document. We designed the app so that your content stays on your device unless you explicitly choose to share it. This privacy policy explains what information the app accesses, how it is used, and the limited situations in which data may leave your computer.

## 1. Information We Access

- **Local files you choose to import.** The app reads only the files and folders you drag in or select through the file picker. Their contents are processed entirely on your device to generate the combined output. Nothing is transmitted to our servers or any third party.
- **App configuration.** Preferences such as theme, editor settings, and extension filters are saved locally using the operating system's standard application storage. We do not collect or sync these settings.
- **Clipboard actions.** When you trigger "Copy context", the generated document is placed on your system clipboard. We do not retain a copy.

## 2. Network Activity

The app does not perform automatic update checks. When you open links (documentation, release notes, GitHub issues, Buy Me a Coffee, etc.), your web browser handles those requests directly under its own privacy policy.

## 3. Third-Party Components

- **Microsoft Edge WebView2 Runtime (Windows only).** Required to embed the Monaco editor. Microsoft may collect basic telemetry about the runtime per their own policies, but Context Collector does not receive that data.
We do not integrate analytics SDKs, crash reporting services, or advertising libraries.

## 4. Data Storage and Retention

All processing happens locally, and any temporary files are kept on your device. To remove your data, simply delete the generated output or the application's settings folder (`AppData/Roaming/context_collector` on Windows or `~/Library/Application Support/Context Collector` on macOS).

## 5. Children’s Privacy

The application is a productivity tool intended for general audiences and does not target children. We do not knowingly collect information from anyone under 13. If you believe a minor has provided us with information, please contact us so we can delete it.

## 6. Your Choices

- Do not add files you do not want the application to process.
- Clear the clipboard or generated documents at any time.

## 7. Changes to This Policy

If the policy changes, we will update the "Last updated" date above and publish the new version in this repository. Continued use of the app after changes take effect constitutes acceptance of the revised policy.

## 8. Contact

If you have privacy questions, open an issue at [https://github.com/omar-hanafy/context_collector/issues](https://github.com/omar-hanafy/context_collector/issues).

---

By using Context Collector, you agree to this policy and acknowledge that the app processes only the data you choose to provide locally on your device.
