<?xml version='1.0' encoding='UTF-8'?>

<!--
DO NOT EDIT - Automatically generated; User-customized logging levels
PLEASE NOTE: Rebooting the Nexus Dogu will reset this file to the configured dogu log level
-->

<included>
    <logger name="com.google.inject.internal.util.Stopwatch" level="{{ .Config.GetOrDefault "logging/root" "WARN"}}"/>
    <logger name="com.orientechnologies" level="{{ .Config.GetOrDefault "logging/root" "WARN"}}"/>
    <logger name="com.orientechnologies.orient.core.storage.impl.local.paginated.OLocalPaginatedStorage" level="{{ .Config.GetOrDefault "logging/root" "WARN"}}"/>
    <logger name="org.apache.http" level="{{ .Config.GetOrDefault "logging/root" "WARN"}}"/>
    <logger name="org.eclipse.jetty" level="{{ .Config.GetOrDefault "logging/root" "WARN"}}"/>
    <logger name="org.eclipse.jetty.webapp" level="{{ .Config.GetOrDefault "logging/root" "WARN"}}"/>
    <logger name="org.eclipse.jetty.webapp.StandardDescriptorProcessor" level="{{ .Config.GetOrDefault "logging/root" "WARN"}}"/>
    <logger name="org.apache.aries" level="{{ .Config.GetOrDefault "logging/root" "WARN"}}"/>
    <logger name="org.apache.felix" level="{{ .Config.GetOrDefault "logging/root" "WARN"}}"/>
    <logger name="org.apache.karaf" level="{{ .Config.GetOrDefault "logging/root" "WARN"}}"/>
</included>
