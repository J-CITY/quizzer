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
}

subprojects {
    if (project.name == "isar_flutter_libs") {
        val config = {
            val androidExt = project.extensions.findByName("android") as? com.android.build.gradle.LibraryExtension
            if (androidExt != null) {
                androidExt.namespace = "dev.isar.isar_flutter_libs"
                androidExt.compileSdk = 34
            }
        }
        if (project.state.executed) {
            config()
        } else {
            project.afterEvaluate { config() }
        }
    }
}
