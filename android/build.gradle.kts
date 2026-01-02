buildscript {
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
    }
}

allprojects {
    // ❌ อย่าใส่ repositories ตรงนี้
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
