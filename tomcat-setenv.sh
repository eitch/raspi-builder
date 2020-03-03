LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CATALINA_HOME/lib
export LD_LIBRARY_PATH
JAVA_OPTS="--add-exports java.base/jdk.internal.misc=ALL-UNNAMED"