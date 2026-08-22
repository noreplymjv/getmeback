# GetMeBack: Code, Design, and Security Audit

This audit evaluates the codebase and user experience of **GetMeBack v1.0.0+1** to identify potential areas of optimization, refactoring, and security enhancement.

---

## 1. Design & UX Audit

### 📈 Layout & Responsiveness
*   **The Grid Spacing (Resolved):** Previously, the vent options screen stretched elements into giant boxes on desktop browsers, forcing excessive scrolling. Replacing this with `SliverGridDelegateWithMaxCrossAxisExtent` successfully resolved the issue by keeping buttons bounded to a maximum width of `140px` and automatically scaling columns (from 3 on mobile to 8+ on laptops).
*   **Text Overflow and Long Names:** 
    *   *Issue:* In [`target_avatar.dart`](file:///media/mj/DATA/GetMeBack/app/lib/widgets/target_avatar.dart#L70), the target's name is displayed in a standard `Text` widget without `maxLines` or `overflow` configurations. If a user names a target *"My noisy neighbor who plays drums at 3 AM"*, it will distort list items and grid spaces.
    *   *Recommendation:* Wrap text with `TextOverflow.ellipsis` and set `maxLines: 1` or `2` inside widgets displaying custom names.

### 🎬 Interactive Feedback
*   **Haptic Consistency:** Haptic calls in [`vent_sfx.dart`](file:///media/mj/DATA/GetMeBack/app/lib/services/vent_sfx.dart#L83) use default flutter settings. On some platforms, these can be intense. 
    *   *Recommendation:* Add a global setting to enable/disable haptics for users who find vibrations distracting.
*   **Swipe/Drag Sensitivity:** In drag-and-drop scenes like `BlenderScene` or `TrashCanScene`, the landing zones are hardcoded offsets.
    *   *Recommendation:* Wrap zones with a proper `DragTarget` widget instead of calculating absolute coordinate heights, preventing alignment bugs when resizing browser windows.

---

## 2. Code & Architecture Audit

### ♻️ Boilerplate Reduction (Base Scene Refactoring)
*   **Current State:** 21 files under [`vent_scenes/`](file:///media/mj/DATA/GetMeBack/app/lib/vent_scenes/) repeat the same code structures:
    ```dart
    late final DramaticFxController _fx = DramaticFxController();
    // listening, disposing, creating custom tickers, wrapping with shell
    ```
*   **Refactoring Plan:** Create an abstract class `StatefulVentScene` to manage the lifecycle of `DramaticFxController` and navigation transitions automatically:
    ```dart
    abstract class VentSceneState<T extends StatefulWidget> extends State<T> with TickerProviderStateMixin {
      late final DramaticFxController fx = DramaticFxController();
      
      @override
      void initState() {
        super.initState();
        fx.addListener(() { if (mounted) setState(() {}); });
      }

      @override
      void dispose() {
        fx.dispose();
        super.dispose();
      }
    }
    ```

### 🔈 Audio Optimization
*   **Pool Re-use:** `VentSfx` loads 4 concurrent players. When playing rapid-fire sounds (e.g. continuous punches), `player.stop()` is chained into `player.play()`. On some low-end Android and web platforms, calling `stop()` and immediately starting can cause minor crackling or audio cutting.
*   **Recommendation:** Use a round-robin player index configuration and cache decoded audio buffers in memory.

### 💾 Data Persistence Limitations
*   **Web Base64 Storage Limit:** 
    *   *Issue:* On the web, uploaded custom photos are converted to base64 data URIs and stored inside `SharedPreferences` (which maps to HTML5 `localStorage`).
    *   *Risk:* Browser `localStorage` is strictly limited to **5MB**. If a user uploads 3 or 4 high-resolution photos, the app will throw a `QuotaExceededError` and crash during writes.
    *   *Recommendation:* Migrate from SharedPreferences to **IndexedDB** (using packages like `hive` or `sembast`) for web photo storage to allow up to hundreds of megabytes of local data storage.

---

## 3. Security & Privacy Audit

### 🔒 Data Privacy
*   **Zero Leakage:** The application has **no network permissions** declared in AndroidManifest, no remote analytics SDKs, and no API integrations. All user data, custom faces, and relief logs are stored purely on-device. This is an exceptional model for privacy-centric utility apps.

### 📁 Permissions & Sanitization
*   **No Sanitization on Inputs:** Target names are rendered directly as strings. Because everything is local-first, the risk of Cross-Site Scripting (XSS) or database injection is negligible. However, basic input filtering should be done to prevent layout breaking via invisible Unicode control characters or newline spam.
*   **File Path Traversal:**
    *   *Current State:* Custom photo paths are saved as absolute strings.
    *   *Risk:* If the app directory changes (e.g., app updates on iOS where path UUIDs change), cached paths may point to missing assets.
    *   *Recommendation:* Save only the file's **relative name** (e.g., `target_images/uuid.jpg`) in preferences, and append it dynamically to `getApplicationDocumentsDirectory().path` at runtime.
