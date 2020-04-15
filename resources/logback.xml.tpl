<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <contextListener class="ch.qos.logback.classic.jul.LevelChangePropagator">
        <resetJUL>true</resetJUL>
    </contextListener>

    <jmxConfigurator/>

    <appender name="console" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{"yyyy-MM-dd HH:mm:ss,SSSZ"} %-5p [%thread] %mdc{userId:-*SYSTEM} %c - %m%n</pattern>
        </encoder>
    </appender>

    <appender name="logfile" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <File>${karaf.data}/log/nexus.log</File>
        <Append>true</Append>
        <encoder class="org.sonatype.nexus.pax.logging.NexusLayoutEncoder">
            <pattern>%d{"yyyy-MM-dd HH:mm:ss,SSSZ"} %-5p [%thread] %node %mdc{userId:-*SYSTEM} %c - %m%n</pattern>
        </encoder>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${karaf.data}/log/nexus-%d{yyyy-MM-dd}.log.gz</fileNamePattern>
            <maxHistory>7</maxHistory>
            <totalSizeCap>10MB</totalSizeCap>
        </rollingPolicy>
        <filter class="org.sonatype.nexus.pax.logging.NexusLogFilter" />
    </appender>

    <appender name="tasklogfile" class="ch.qos.logback.classic.sift.SiftingAppender">
        <filter class="org.sonatype.nexus.pax.logging.TaskLogsFilter" />
        <discriminator>
            <key>taskIdAndDate</key>
            <defaultValue>unknown</defaultValue>
        </discriminator>
        <sift>
            <appender name="taskAppender" class="ch.qos.logback.core.ConsoleAppender">
                <encoder class="org.sonatype.nexus.pax.logging.NexusLayoutEncoder">
                    <pattern>%d{"yyyy-MM-dd HH:mm:ss,SSSZ"} %-5p [%thread] %node %mdc{userId:-*SYSTEM} %c - %m%n</pattern>
                </encoder>
            </appender>
        </sift>
    </appender>

    <appender name="metrics" class="org.sonatype.nexus.pax.logging.InstrumentedAppender"/>

    <logger name="org.eclipse.jetty.webapp" level="{{ .Config.GetOrDefault "logging/root" "WARN"}}"/>
    <logger name="org.eclipse.jetty.webapp.StandardDescriptorProcessor" level="{{ .Config.GetOrDefault "logging/root" "WARN"}}"/>

    <logger name="org.apache.aries" level="{{ .Config.GetOrDefault "logging/root" "WARN"}}"/>
    <logger name="org.apache.felix" level="{{ .Config.GetOrDefault "logging/root" "WARN"}}"/>
    <logger name="org.apache.karaf" level="{{ .Config.GetOrDefault "logging/root" "WARN"}}"/>

    <include file="${karaf.data}/etc/logback/logback-overrides.xml" optional="true"/>

    <!-- root.level enters as environment variable via the logback-overrides.xml -->
    <root level="${root.level:-{{ .Config.GetOrDefault "logging/root" "WARN"}}}">
        <appender-ref ref="console"/>
        <appender-ref ref="logfile"/>
    </root>
</configuration>
