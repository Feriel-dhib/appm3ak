import org.gradle.api.JavaVersion
import org.gradle.api.tasks.compile.JavaCompile

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
// Ne pas utiliser evaluationDependsOn(":app") : ordre d’évaluation incompatible avec
// afterEvaluate sur Gradle récent (« already evaluated »).

// Évite les warnings Java 8 des plugins (ML Kit, etc.) sans afterEvaluate (lazy, tous sous-projets).
subprojects {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
        val args = options.compilerArgs
        if (args.none { it == "-Xlint:-options" }) {
            args.add("-Xlint:-options")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
