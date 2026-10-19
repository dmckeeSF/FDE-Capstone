public with sharing class ReservationBookingRefHelper {
    private static final String CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    public static String generate() {
        String ref = '';
        Integer len = CHARS.length();
        for (Integer i = 0; i < 8; i++) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), len);
            ref += CHARS.substring(idx, idx + 1);
        }
        return ref;
    }
}
