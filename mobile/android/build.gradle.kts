allprojects { repositories { google(); mavenCentral() } }
val trackerBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(trackerBuildDir)
subprojects {
    layout.buildDirectory.value(trackerBuildDir.dir(project.name))
    evaluationDependsOn(":app")
}
tasks.register<Delete>("clean") { delete(rootProject.layout.buildDirectory) }
