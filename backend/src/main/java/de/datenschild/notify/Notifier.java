package de.datenschild.notify;

import de.datenschild.breach.BreachInfo;

import java.util.List;

public interface Notifier {

    void sendVerificationCode(String email, String code);

    void sendNewBreaches(String email, String maskedEmail, List<BreachInfo> breaches);
}
