# Simple Webapp

For Openshift S2I demos with a customized driver (MariaDB) with the OCP EAP builder image.


## Configure custom Drivers dynamically

You can just run it via `oc` with the files provided in the extensions folder of this repo.

```bash
 oc create configmap jboss-cli --from-file=postconfigure.sh=extensions/postconfigure.sh --from-file=extensions.cli=extensions/extensions.cli
 ```

And then add it to your `DeploymentConfig`.
 ```bash
 oc set volume dc/eap-app --add --name=jboss-cli -m /opt/eap/extensions -t configmap --configmap-name=jboss-cli --default-mode='0755' --overwrite
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


## Configure Datasource Settings

Create a `ConfigMap` or `Secret` to inject `ENV` variables into your `deployment`/`deploymentconfig`.

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
```