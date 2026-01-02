buildscript {
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
