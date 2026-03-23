# Patient app — appointments only

The patient side is focused on:

1. **Booking** an appointment with the doctor (details needed for the visit).
2. **Viewing** saved **appointment requests** and **full details** for each (tap a card on **My appointments**).

## Where to find things

| Feature | Where |
|--------|--------|
| Book | Home gradient card, Profile → Book, **My appointments** FAB |
| List + details | Profile → My appointments, Footer → calendar, Home “View appointments” |

## Profile

- **Appointments:** Book · My appointments · My health information (info reused when booking; no insurance or family flows).
- **Account:** Notifications (placeholder).
- **General / Security:** unchanged; unimplemented items show “coming soon”.

## Data layer (API-ready)

- Patient UI now talks to `PatientRepository` (`lib/feature/patientsPages/model/patient_repository.dart`) instead of reading storage directly.
- Current implementation is `LocalPatientRepository` (uses `StorageService` under the hood).
- For backend integration, swap `PatientRepository.instance` to an API implementation and keep UI code unchanged.
- `getSlotsForDate(date)` is the single source for slot availability (booked/free), so backend slot APIs plug in here.

## Constants

`kPatientAppDoctorName` / `kPatientAppDoctorSpecialty` in `patient_book_appointment_view.dart` — keep aligned with the home card.
