import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

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

// --- JVM 17 consistency: fixes the Java(1.8)/Kotlin(21) mismatch in plugins like tflite_flutter ---
subprojects {
    // Kotlin side: 17 (configureEach is lazy; applies as tasks are created)
    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }

    // Java side: force 17 AFTER the plugin sets its own compileOptions (1.8).
    val forceJava17: Project.() -> Unit = {
        extensions.findByType(com.android.build.api.dsl.LibraryExtension::class.java)?.apply {
            // The plugin's compileSdk (31) is below its AndroidX deps; bump to 36.
            compileSdk = 36
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
    // :app is already evaluated, so afterEvaluate would throw on it; check the state.
    if (state.executed) forceJava17() else afterEvaluate { forceJava17() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}