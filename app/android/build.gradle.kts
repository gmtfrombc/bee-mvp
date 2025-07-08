allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
    // Workaround for uni_links <1.0 lacking AGP 8 namespace
    if (name == "uni_links") {
        afterEvaluate {
            extensions.findByName("android")?.let { ext ->
                (ext as? com.android.build.gradle.LibraryExtension)?.apply {
                    namespace = "name.avioli.unilinks"
                    println("🔧 Applied namespace workaround for uni_links -> $namespace")
                }
            }
        }
    }
}
