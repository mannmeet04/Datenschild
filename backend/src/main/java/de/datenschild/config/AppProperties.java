package de.datenschild.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app")
public record AppProperties(Crypto crypto, Breach breach, Monitor monitor, Limits limits, Mail mail) {

    public record Crypto(String masterKey) {}

    public record Breach(String provider, String hibpApiKey, String userAgent) {}

    public record Monitor(String cron, long delayMs) {}

    public record Limits(int maxEmailsPerDevice,
                         int verificationTtlMinutes,
                         int maxVerifyAttempts,
                         int unverifiedRetentionHours,
                         int inactiveDeviceRetentionDays) {}

    public record Mail(boolean enabled, String from) {}
}
