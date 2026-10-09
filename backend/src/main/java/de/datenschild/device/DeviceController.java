package de.datenschild.device;

import de.datenschild.web.RateLimiter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.time.Duration;

@RestController
@RequestMapping("/api/v1/devices")
public class DeviceController {

    public record PushTokenRequest(@Size(max = 512) String pushToken) {}

    private final DeviceService deviceService;
    private final RateLimiter rateLimiter;

    public DeviceController(DeviceService deviceService, RateLimiter rateLimiter) {
        this.deviceService = deviceService;
        this.rateLimiter = rateLimiter;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public DeviceService.Registration register(HttpServletRequest request) {
        rateLimiter.check("register:" + request.getRemoteAddr(), 10, Duration.ofHours(1));
        return deviceService.register();
    }

    @PutMapping("/me/push-token")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void pushToken(@RequestHeader(HttpHeaders.AUTHORIZATION) String auth,
                          @Valid @RequestBody PushTokenRequest body) {
        deviceService.updatePushToken(deviceService.authenticate(auth), body.pushToken());
    }

    @DeleteMapping("/me")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteMe(@RequestHeader(HttpHeaders.AUTHORIZATION) String auth) {
        deviceService.deleteEverything(deviceService.authenticate(auth));
    }
}
