ttn0224@cell04-cse:~/CSCE3444/s1-t1$ git checkout master
Already on 'master'
Your branch and 'origin/master' have diverged,
and have 1 and 47 different commits each, respectively.
  (use "git pull" to merge the remote branch into yours)
ttn0224@cell04-cse:~/CSCE3444/s1-t1$ git pull orgin master
fatal: 'orgin' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
ttn0224@cell04-cse:~/CSCE3444/s1-t1$ git merge feature-thuannguyen
CONFLICT (add/add): Merge conflict in app.build.gradle.kts
Auto-merging app.build.gradle.kts
Auto-merging README.md
CONFLICT (content): Merge conflict in README.md
Automatic merge failed; fix conflicts and then commit the result.
ttn0224@cell04-cse:~/CSCE3444/s1-t1$ git push origin master
To csegitlab.engineering.unt.edu:csce-3444/fall2025/s1-t1.git
 ! [rejected]        master -> master (non-fast-forward)
error: failed to push some refs to 'git@csegitlab.engineering.unt.edu:csce-3444/fall2025/s1-t1.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. Integrate the remote changes (e.g.
hint: 'git pull ...') before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
ttn0224@cell04-cse:~/CSCE3444/s1-t1$ nano Reads1.md
ttn0224@cell04-cse:~/CSCE3444/s1-t1$ git add Reads1.md
ttn0224@cell04-cse:~/CSCE3444/s1-t1$ nano Reads1.md
ttn0224@cell04-cse:~/CSCE3444/s1-t1$ git add Reads1.md
ttn0224@cell04-cse:~/CSCE3444/s1-t1$ git checkout feature-thuannguyen
README.md: needs merge
app.build.gradle.kts: needs merge
error: you need to resolve your current index first
ttn0224@cell04-cse:~/CSCE3444/s1-t1$ nano Reads1.md
ttn0224@cell04-cse:~/CSCE3444/s1-t1$ git add Reads1.md
ttn0224@cell04-cse:~/CSCE3444/s1-t1$ git commit -m "Add README explaining backend files for Abhiram's frontend"
U	README.md
U	app.build.gradle.kts
error: Committing is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: Exiting because of an unresolved conflict.
ttn0224@cell04-cse:~/CSCE3444/s1-t1$ git push origin feature-thuannguyen
Everything up-to-date
ttn0224@cell04-cse:~/CSCE3444/s1-t1$ ls
app.build.gradle.kts  build.gradle.kts  pubspec.yaml  README.md  Reads1.md  s1-t1
ttn0224@cell04-cse:~/CSCE3444/s1-t1$ cat app.build.gradle.kts 
plugins {
<<<<<<< HEAD
    // Add the dependency for the Google services Gradle plugin
    id("com.google.gms.google-services") version "4.4.3" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
=======
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.android.application")
    id("com.google.gms.google-services")  
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))
    // Other Firebase dependencies like auth, firestore, storage
}

android {
    namespace = "com.example.style_sync"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.style_sync"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
>>>>>>> feature-thuannguyen
}
ttn0224@cell04-cse:~/CSCE3444/s1-t1$ 
