# A Simple Webapp for OpenShift

This is a simple Web Archive (WAR) application to demonstrate deployments with OpenShift.

The application's root context is `/demo`

A curl-friendly hostname checker is available at `/demo/host`

It leverages several features from OpenShift's S2I build strategy, which allows images to be built directly from source code, using the base image `jboss-eap72-openshift:1.1` from Red Hat.  Their base image includes built-in scripting that allows several core EAP configurations to be dynamically configured at runtime.


## EAP image conventions

This project contains several folders not found in a typical `Maven` project.  The `jboss-eap72-openshift` automatically scans for and places contents of these folders into specific EAP locations.

- modules/* gets placed in $JBOSS_HOME/modules 
- configuration/* copied to $JBOSS_HOME/standalone/configuration
- deployments/* copied to $JBOSS_HOME/standalone/deployments

Also note that `standalone-openshift.xml` replaces the default `standalone.xml` when running within OpenShift.  The OpenShift version is configured to do discovery and networking with OpenShift in mind, and probably won't work with other PaaS systems.


## Configure Drivers Dynamically

A folder named `extensions` is provided that contains some `jboss-cli` scripts to dynamically configure JDBC Drivers for use with Datasources.

You can just run it via `oc` with the files provided in the extensions folder of this repo.

```bash
 oc create configmap jboss-cli --from-file=postconfigure.sh=extensions/postconfigure.sh --from-file=extensions.cli=extensions/extensions.cli
 ```

And then add it to your `DeploymentConfig`.  Don't forget to change `hello-openshift` to the actual name of your `DeploymentConfig`.
 ```bash
 oc set volume dc/hello-openshift --add --name=jboss-cli -m /opt/eap/extensions -t configmap --configmap-name=jboss-cli --default-mode='0755' --overwrite
 ```

There's nothing special about it, it just creates a `ConfigMap` with data that looks like this.  Look in the extensions folder to see for yourself.
```yaml
  extensions.cli: |
    embed-server --std-out=echo  --server-config=standalone-openshift.xml
    /subsystem=datasources/jdbc-driver=mariadb:add(driver-name=mariadb,driver-module-name=org.mariadb,driver-xa-datasource-class-name=org.mariadb.jdbc.MariaDbDataSource,driver-class-name=org.mariadb.jdbc.Driver)
    quit
  postconfigure.sh: |
    #!/usr/bin/env bash
    set -x
    echo "Executing postconfigure.sh"
    $JBOSS_HOME/bin/jboss-cli.sh --file=$JBOSS_HOME/extensions/extensions.cli
```

When the pod restarts, you should see similar output at the top of the logs.

```bash
+ echo 'Executing postconfigure.sh'
Executing postconfigure.sh
+ /opt/eap/bin/jboss-cli.sh --file=/opt/eap/extensions/extensions.cli
[0m14:07:08,597 INFO  [org.jboss.modules] (CLI command executor) JBoss Modules version 1.8.8.Final-redhat-00001
[0m[0m14:07:08,898 INFO  [org.jboss.msc] (CLI command executor) JBoss MSC version 1.4.5.Final-redhat-00001
[0m[0m14:07:08,908 INFO  [org.jboss.threads] (CLI command executor) JBoss Threads version 2.3.2.Final-redhat-1
[0m[0m14:07:09,498 INFO  [org.jboss.as] (MSC service thread 1-2) WFLYSRV0049: JBoss EAP 7.2.3.GA (WildFly Core 6.0.15.Final-redhat-00001) starting
```


## Configure Datasources as Environment Variables

Create a `ConfigMap` or `Secret` to inject `ENV` variables into your `Deployment`/`DeploymentConfig`.

```yaml
data:
  DB_SERVICE_PREFIX_MAPPING: example-mariadb=DS1
  DS1_DRIVER: mariadb
  DS1_JNDI: 'java:/example'
  DS1_URL: jdbc:mariadb://mariadb.eap-demo.svc.cluster.local:3306/test
  DS1_DATABASE: test
  DS1_USERNAME: user
  DS1_PASSWORD: password
  DS1_CONNECTION_CHECKER: org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLValidConnectionChecker
  DS1_EXCEPTION_SORTER: org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLExceptionSorter
  DS1_NONXA: "true"
  EXAMPLE_MARIADB_SERVICE_PORT: '3306'
  EXAMPLE_MARIADB_SERVICE_HOST: mariadb.eap-demo.svc.cluster.local
```



## Configure Datasources as a Projected Environment File

The implementation of this has some subtle differences.  Note the use of the `DATASOURCES` property, whereas the other method uses `DB_SERVICE_PREFIX_MAPPING` to create "short" names for the ENV properties.

`DATASOURCES` takes a comma-separated list if you have multiple datasources to configure.

```properties
DATASOURCES=DS1
DS1_JNDI=java:/example
DS1_DRIVER=mariadb
DS1_USERNAME=user
DS1_PASSWORD=password
DS1_MAX_POOL_SIZE=20
DS1_MIN_POOL_SIZE=10
DS1_CONNECTION_CHECKER=org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLValidConnectionChecker
DS1_EXCEPTION_SORTER=org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLExceptionSorter
DS1_URL=jdbc:mariadb://mariadb.eap-demo.svc.cluster.local:3306/test
DS1_NONXA=true
```