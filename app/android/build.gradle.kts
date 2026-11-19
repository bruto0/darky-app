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

// Flutter's template moves the build directory of every Gradle project into <flutter>/build.
// That only works while a project's sources and its build directory share the same file-system
// root: AGP computes some inputs with `buildDir.toRelativeString(projectDir)`, and Gradle's
// Kotlin helper throws "this and base files have different roots" for e.g. C:\ vs J:\.
// Android plugins are resolved from the pub cache (C:\Users\kir\AppData\Local\Pub\Cache\...)
// while this project lives on J:\, so those plugin projects keep their default build directory
// next to their own sources. Without this, Android Studio's Gradle sync fails with
// "Could not create task ':<plugin>:generate<Variant>UnitTestConfig'".
subprojects {
    val buildDirRoot = newBuildDir.asFile.toPath().root?.toString().orEmpty()
    val projectDirRoot = project.projectDir.toPath().root?.toString().orEmpty()
    if (buildDirRoot.equals(projectDirRoot, ignoreCase = true)) {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
