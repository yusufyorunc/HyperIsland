package io.github.hyperisland.xposed

import io.github.hyperisland.xposed.hook.DownloadHook
import io.github.hyperisland.xposed.hook.FocusNotifStatusBarIconHook
import io.github.hyperisland.xposed.hook.GenericProgressHook
import io.github.hyperisland.xposed.hook.IslandDispatcherHook
import io.github.hyperisland.xposed.hook.MarqueeHook
import io.github.hyperisland.xposed.hook.UnlockAllFocusHook
import io.github.hyperisland.xposed.hook.UnlockFocusAuthHook
import io.github.libxposed.api.XposedModule
import io.github.libxposed.api.XposedModuleInterface.PackageLoadedParam

class HyperIslandModule : XposedModule() {

    override fun onPackageLoaded(param: PackageLoadedParam) {
        when (param.packageName) {

            "com.android.systemui" -> {
                IslandDispatcherHook.init(this, param)
                GenericProgressHook.init(this, param)
                MarqueeHook.init(this, param)
                UnlockAllFocusHook.init(this, param)
                FocusNotifStatusBarIconHook.init(this, param)
            }

            "com.android.providers.downloads",
            "com.xiaomi.android.app.downloadmanager",
                ->
                DownloadHook.init(this, param)

            "com.xiaomi.xmsf" ->
                UnlockFocusAuthHook.init(this, param)
        }
    }
}
