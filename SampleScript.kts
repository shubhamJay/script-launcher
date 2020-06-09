import esw.ocs.dsl.core.script

script {
    println("loading Script")

    onSetup("command-1") { x ->
        println("Command received" + x)
    }
}
