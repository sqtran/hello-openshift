# A Simple Webapp for OpenShift, JBoss EAP, and S2I Builds

This is a simple Web Archive (WAR) application to demonstrate deployments with OpenShift.

The application's root context is `/demo`

A curl-friendly hostname checker is available at `/demo/host`

It leverages several features from OpenShift's S2I build strategy, which allows images to be built directly from source code, using the base image `jboss-eap72-openshift:1.1` from Red Hat.  Their base image includes built-in scripting that allows several core EAP configurations to be dynamically configured at runtime.


## EAP Image Conventions

This project contains several folders not found in a typical `Maven` project.  The `jboss-eap72-openshift` automatically scans for and places contents of these folders into specific EAP locations.

- modules/* gets placed in $JBOSS_HOME/modules
- configuration/* copied to $JBOSS_HOME/standalone/configuration
- deployments/* copied to $JBOSS_HOME/standalone/deployments

Also note that `standalone-openshift.xml` replaces the default `standalone.xml` when running within OpenShift.  The OpenShift version is configured to do discovery and networking with OpenShift in mind, and probably won't work with other PaaS systems.


## Prerequisites

This application relies on having a database available.  Since we're running on OpenShift, I instantiated an emphermal MariaDB database, and used the SQL script `mariadb-sample.sql` to configure and populate the database with sample data.  You can use an existing database, but the values in the examples below will need to be adjusted accordingly.


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


## Configuring Datasources Dynamically

Here are two options for configuring datasources dynamically.

### Option 1: As Environment Variables

You can dynamcially create Datasources at runtime by injecting Environment variables into your `Deployment`/`DeploymentConfig`.  The settings can be added via single values (env), or as all values from a `ConfigMap` or `Secret`.

These are sample properties that a `ConfigMap` would need in order to configure a datasource.
```yaml
data:
  DB_SERVICE_PREFIX_MAPPING: example-mariadb=DS1
  DS1_DRIVER: mariadb
  DS1_JNDI: 'java:/example'
  DS1_URL: jdbc:mariadb://mariadb.<namespace>.svc.cluster.local:3306/test
  DS1_DATABASE: test
  DS1_USERNAME: user
  DS1_PASSWORD: password
  DS1_CONNECTION_CHECKER: org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLValidConnectionChecker
  DS1_EXCEPTION_SORTER: org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLExceptionSorter
  DS1_NONXA: "true"
  EXAMPLE_MARIADB_SERVICE_PORT: '3306'
  EXAMPLE_MARIADB_SERVICE_HOST: mariadb.<namespace>.svc.cluster.local
```

And here's a PostgreSQL example if you don't want to just use the default drivers.
```yaml
data:
  DB_SERVICE_PREFIX_MAPPING: example-psql=DS1
  DS1_DRIVER: postgresql
  DS1_JNDI: 'java:/example'
  DS1_URL: jdbc:postgresql://postgresql.<namespace>.svc.cluster.local:5432/test
  DS1_DATABASE: test
  DS1_USERNAME: user
  DS1_PASSWORD: password
  DS1_CONNECTION_CHECKER: org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLValidConnectionChecker
  DS1_EXCEPTION_SORTER: org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLExceptionSorter
  DS1_NONXA: "true"
  EXAMPLE_MARIADB_SERVICE_PORT: '5432'
  EXAMPLE_MARIADB_SERVICE_HOST: postgresql.<namespace>.svc.cluster.local
```
Note that you can only use one or the other.  Both examples are configured to use the same `java:/example` JNDI name, so you have to give them both unique names, or just use one of them.  The code is only looking for `java:/example`.

### Option 2: Projected Environment File(s) into a Volume

The implementation of this has some subtle differences.  Note the use of the `DATASOURCES` property, whereas the other method uses `DB_SERVICE_PREFIX_MAPPING` to create "short" names for the ENV properties.


These are sample properties that a `Secret` would need in order to configure a datasource.  Note the key is the name of the file, which is in properties file format, not `YAML`.

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
DS1_URL=jdbc:mariadb://mariadb.<namespace>.svc.cluster.local:3306/test
DS1_NONXA=true
```

**Note: For whatever reason, each line of my properties file started with two spaces when I cut and pasted.  Make sure you remove those spaces so everything is left-aligned.**


You'll need to project this `Secret` as a volume into your container.  The location doesn't really matter, but don't override any critical folders required for EAP to function properly.  I followed previous examples and projected it into `/etc/extensions`.

Finally, set the `ENV_FILES` ENV variable, which takes a comma-separated list if you projected your Datasources into multiple volumes.  If you have a single `Secret` that contains multiple files, you will need to list out all the files to be processed.


## Static Configurations

Everything I've demonstrated so far has been for dynamic configurations, but you'll also notice that I provided a `configuration/standalone-openshift.xml` file.  You can always statically configure EAP by passing in your own file.  The example configuration is the default `jboss-eap72-openshift:1.1`'s configuration file, so make sure you always use the latest version specific to your image.


## Best of Both Worlds
You can use both static and dynamic configuration methods to fine tune your EAP instance.  Pass in your own standalone-openshift.xml file and use ENV variables or custom jboss-cli scripts to configure EAP the way that you need it.

Note the placeholders throughout `standalone-openshift.xml` such as `<!-- ##DATASOURCES## -->` and `<!-- ##ELYTRON_KEY_STORE## -->`.  These are markers where the EAP base image inject calculated values, which are derived dynamically via built-in scripting.

## Dynamic standalone-openshift.xml with ENV variables

You can easily modify the existing `standalone-openshift.xml` with other runtime configurations with expression evalulations.  Through the configuration file, just reference an ENV variable with the `env.` prefix, and provide default values as needed.  This project has a sample setting for the logging level.  Set the ENV variable `CUSTOM_LOG_LEVEL` anywhere you choose to override the default value of INFO.  It would look like the following in the XML - `${env.CUSTOM_LOG_LEVEL:INFO}`.

Note that not all properties in the XML support expressions.  A field like the data-source `pool-name` needs a static name that cannot be configured at runtime.