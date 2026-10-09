package de.datenschild.email;

import de.datenschild.device.DeviceService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/emails")
public class EmailController {

    public record AddRequest(@NotBlank @Email @Size(max = 254) String email) {
        public AddRequest {
            email = email == null ? null : email.trim();
        }
    }

    public record VerifyRequest(@NotBlank @Pattern(regexp = "\\d{6}") String code) {}

    private final EmailService emailService;
    private final DeviceService deviceService;

    public EmailController(EmailService emailService, DeviceService deviceService) {
        this.emailService = emailService;
        this.deviceService = deviceService;
    }

    @GetMapping
    public List<EmailService.EmailView> list(@RequestHeader(HttpHeaders.AUTHORIZATION) String auth) {
        return emailService.list(deviceService.authenticate(auth));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public EmailService.EmailView add(@RequestHeader(HttpHeaders.AUTHORIZATION) String auth,
                                      @Valid @RequestBody AddRequest body) {
        return emailService.add(deviceService.authenticate(auth), body.email());
    }

    @PostMapping("/{id}/verify")
    public EmailService.EmailView verify(@RequestHeader(HttpHeaders.AUTHORIZATION) String auth,
                                         @PathVariable UUID id, @Valid @RequestBody VerifyRequest body) {
        return emailService.verify(deviceService.authenticate(auth), id, body.code());
    }

    @PostMapping("/{id}/resend")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void resend(@RequestHeader(HttpHeaders.AUTHORIZATION) String auth, @PathVariable UUID id) {
        emailService.resendCode(deviceService.authenticate(auth), id);
    }

    @PostMapping("/{id}/refresh")
    public EmailService.EmailView refresh(@RequestHeader(HttpHeaders.AUTHORIZATION) String auth,
                                          @PathVariable UUID id) {
        return emailService.refresh(deviceService.authenticate(auth), id);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@RequestHeader(HttpHeaders.AUTHORIZATION) String auth, @PathVariable UUID id) {
        emailService.delete(deviceService.authenticate(auth), id);
    }
}
