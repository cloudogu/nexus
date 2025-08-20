<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <contextListener class="ch.qos.logback.classic.jul.LevelChangePropagator">
        <resetJUL>true</resetJUL>
    </contextListener>

    <jmxConfigurator/>

    <appender name="osgi" class="ch.qos.logback.core.ConsoleAppender">
        <filter class="org.sonatype.nexus.logging.NexusLogFilter" />
    </appender>

    <appender name="console" class="ch.qos.logback.core.ConsoleAppender">
        <filter class="org.sonatype.nexus.logging.NexusLogFilter" />
        <encoder>
            <pattern>%d{"yyyy-MM-dd HH:mm:ss,SSSZ"} %-5p [%thread] %mdc{userId:-*SYSTEM} %c - %m%n</pattern>
        </encoder>
    </appender>

    <appender name="logfile" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <File>${karaf.data}/log/nexus.log</File>
        <Append>true</Append>
        <encoder class="org.sonatype.nexus.logging.NexusLayoutEncoder">
            <pattern>%d{"yyyy-MM-dd HH:mm:ss,SSSZ"} %-5p [%thread] %node %mdc{userId:-*SYSTEM} %c - %m%n</pattern>
        </encoder>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${karaf.data}/log/nexus-%d{yyyy-MM-dd}.log.gz</fileNamePattern>
            <maxHistory>14</maxHistory>
            <totalSizeCap>20MB</totalSizeCap>
        </rollingPolicy>
        <filter class="org.sonatype.nexus.logging.NexusLogFilter" />
    </appender>

    <appender name="clusterlogfile" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <File>${karaf.data}/log/nexus_cluster.log</File>
        <Append>true</Append>
        <encoder class="org.sonatype.nexus.logging.NexusLayoutEncoder">
            <pattern>%d{"yyyy-MM-dd HH:mm:ss,SSSZ"} %-5p [%thread] %node %mdc{userId:-*SYSTEM} %c - %m%n</pattern>
        </encoder>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${karaf.data}/log/nexus_cluster-%d{yyyy-MM-dd}.log.gz</fileNamePattern>
            <maxHistory>14</maxHistory>
            <totalSizeCap>20MB</totalSizeCap>
        </rollingPolicy>
        <filter class="org.sonatype.nexus.logging.ClusterLogFilter" />
    </appender>

    <appender name="tasklogfile" class="ch.qos.logback.classic.sift.SiftingAppender">
        <filter class="org.sonatype.nexus.logging.TaskLogsFilter" />
        <discriminator>
            <key>taskIdAndDate</key>
            <defaultValue>unknown</defaultValue>
        </discriminator>
        <sift>
            <appender name="taskAppender" class="ch.qos.logback.core.FileAppender">
                <file>${karaf.data}/log/tasks/${taskIdAndDate}.log</file>
                <encoder class="org.sonatype.nexus.logging.NexusLayoutEncoder">
                    <pattern>%d{"yyyy-MM-dd HH:mm:ss,SSSZ"} %-5p [%thread] %node %mdc{userId:-*SYSTEM} %c - %m%n</pattern>
                </encoder>
            </appender>
        </sift>
    </appender>

    <appender name="auditlogfile" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <File>${karaf.data}/log/audit/audit.log</File>
        <Append>true</Append>
        <encoder>
            <pattern>%msg%n</pattern>
        </encoder>
        <filter class="org.sonatype.nexus.logging.AuditLogFilter"/>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${karaf.data}/log/audit/audit-%d{yyyy-MM-dd}.log.gz</fileNamePattern>
            <maxHistory>14</maxHistory>
            <totalSizeCap>20MB</totalSizeCap>
        </rollingPolicy>
    </appender>

    <logger name="auditlog" additivity="false">
        <appender-ref ref="auditlogfile"/>
    </logger>

    <appender name="metrics" class="org.sonatype.nexus.logging.InstrumentedAppender"/>

    <logger name="org.eclipse.jetty.webapp" level="${root.level:-{{ .Config.GetOrDefault "logging/root" "WARN"}}}"/>
    <logger name="org.eclipse.jetty.webapp.StandardDescriptorProcessor" level="${root.level:-{{ .Config.GetOrDefault "logging/root" "WARN"}}}"/>

    <logger name="org.apache.aries" level="${root.level:-{{ .Config.GetOrDefault "logging/root" "WARN"}}}"/>
    <logger name="org.apache.felix" level="${root.level:-{{ .Config.GetOrDefault "logging/root" "WARN"}}}"/>
    <logger name="org.apache.karaf" level="${root.level:-{{ .Config.GetOrDefault "logging/root" "WARN"}}}"/>

    <include file="${karaf.data}/etc/logback/logback-overrides.xml" optional="true"/>

    <root level="${root.level:-{{ .Config.GetOrDefault "logging/root" "WARN"}}}">
        <appender-ref ref="osgi"/>
        <appender-ref ref="console"/>
        <appender-ref ref="logfile"/>
        <appender-ref ref="clusterlogfile"/>
        <appender-ref ref="tasklogfile"/>
        <appender-ref ref="metrics"/>
    </root>
</configuration>


