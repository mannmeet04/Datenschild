package de.datenschild;

import de.datenschild.config.AppProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
@EnableConfigurationProperties(AppProperties.class)
public class DatenschildApplication {

    public static void main(String[] args) {
        SpringApplication.run(DatenschildApplication.class, args);
    }
}
