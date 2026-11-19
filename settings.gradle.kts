pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        // Guardian Project's API-21-compatible Tor Android wrapper (Tor 0.4.8.16).
        // The current 0.4.9.x wrapper has minSdk 24 and prevents Android 6 builds.
        maven {
            name = "guardianProject"
            url = uri("https://raw.githubusercontent.com/guardianproject/gpmaven/master")
            content { includeModule("info.guardianproject", "tor-android") }
        }
        // Psiphon's own binary distribution. It is a maven layout served out of
        // a git repository rather than a repository manager, which is how
        // Psiphon publish it -- see MobileLibrary/Android in psiphon-tunnel-core.
        //
        // Scoped to their group alone. A repository this far outside the usual
        // supply chain has no business being asked for anything else, and an
        // unscoped one would be consulted for every dependency we resolve.
        maven {
            name = "psiphon"
            url = uri("https://raw.githubusercontent.com/Psiphon-Labs/psiphon-tunnel-core-Android-library/master")
            content { includeGroup("ca.psiphon") }
        }
    }
}

rootProject.name = "WhiteAestherMobile"
include(":app")
