import com.android.build.gradle.LibraryExtension
import com.android.build.gradle.AppExtension

allprojects {
    repositories {
        google()
        mavenCentral()
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

subprojects {
  // per i moduli library
  plugins.withId("com.android.library") {
    extensions.configure<LibraryExtension> {
      if (namespace.isNullOrEmpty()) {
        namespace = project.group.toString().ifEmpty { "com.example" }
      }
    }
  }
  // per il modulo app
  plugins.withId("com.android.application") {
    extensions.configure<AppExtension> {
      if (namespace.isNullOrEmpty()) {
        namespace = project.group.toString().ifEmpty { "com.example" }
      }
    }
  }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
