class NewPatientResponse {
  String? patientId;
  String? createdBy;
  Profile? profile;
  Contact? contact;
  MedicalHistory? medicalHistory;
  Appointment? appointment;
  Records? records;

  NewPatientResponse(
      {this.patientId,
      this.createdBy,
      this.profile,
      this.contact,
      this.medicalHistory,
      this.appointment,
      this.records});

  NewPatientResponse.fromJson(Map<String, dynamic> json) {
    patientId = json['patient_id'];
    createdBy = json['created_by'];
    profile =
        json['profile'] != null ? Profile.fromJson(json['profile']) : null;
    contact =
        json['contact'] != null ? Contact.fromJson(json['contact']) : null;
    medicalHistory = json['medical_history'] != null
        ? MedicalHistory.fromJson(json['medical_history'])
        : null;
    appointment = json['appointment'] != null
        ? Appointment.fromJson(json['appointment'])
        : null;
    records =
        json['records'] != null ? Records.fromJson(json['records']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['patient_id'] = patientId;
    data['created_by'] = createdBy;
    if (profile != null) {
      data['profile'] = profile!.toJson();
    }
    if (contact != null) {
      data['contact'] = contact!.toJson();
    }
    if (medicalHistory != null) {
      data['medical_history'] = medicalHistory!.toJson();
    }
    if (appointment != null) {
      data['appointment'] = appointment!.toJson();
    }
    if (records != null) {
      data['records'] = records!.toJson();
    }
    return data;
  }
}

class Profile {
  String? name;
  String? age;
  String? gender;
  String? bloodGroup;
  String? weight;
  String? height;
  bool? isVerified;

  Profile(
      {this.name,
      this.age,
      this.gender,
      this.bloodGroup,
      this.weight,
      this.height,
      this.isVerified});

  Profile.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    age = json['age'];
    gender = json['gender'];
    bloodGroup = json['blood_group'];
    weight = json['weight'];
    height = json['height'];
    isVerified = json['is_verified'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['age'] = age;
    data['gender'] = gender;
    data['blood_group'] = bloodGroup;
    data['weight'] = weight;
    data['height'] = height;
    data['is_verified'] = isVerified;
    return data;
  }
}

class Contact {
  String? phone;
  String? email;
  String? address;

  Contact({this.phone, this.email, this.address});

  Contact.fromJson(Map<String, dynamic> json) {
    phone = json['phone'];
    email = json['email'];
    address = json['address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['phone'] = phone;
    data['email'] = email;
    data['address'] = address;
    return data;
  }
}

class MedicalHistory {
  String? historyNotes;
  String? currentMedications;
  String? allergies;
  String? lastVisitDate;

  MedicalHistory(
      {this.historyNotes,
      this.currentMedications,
      this.allergies,
      this.lastVisitDate});

  MedicalHistory.fromJson(Map<String, dynamic> json) {
    historyNotes = json['history_notes'];
    currentMedications = json['current_medications'];
    allergies = json['allergies'];
    lastVisitDate = json['last_visit_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['history_notes'] = historyNotes;
    data['current_medications'] = currentMedications;
    data['allergies'] = allergies;
    data['last_visit_date'] = lastVisitDate;
    return data;
  }
}

class Appointment {
  String? appointmentId;
  String? scheduledTime;
  String? diagnosis;
  String? symptoms;
  String? status;

  Appointment(
      {this.appointmentId,
      this.scheduledTime,
      this.diagnosis,
      this.symptoms,
      this.status});

  Appointment.fromJson(Map<String, dynamic> json) {
    appointmentId = json['appointment_id'];
    scheduledTime = json['scheduled_time'];
    diagnosis = json['diagnosis'];
    symptoms = json['symptoms'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['appointment_id'] = appointmentId;
    data['scheduled_time'] = scheduledTime;
    data['diagnosis'] = diagnosis;
    data['symptoms'] = symptoms;
    data['status'] = status;
    return data;
  }
}

class Records {
  List<DoctorNotes>? doctorNotes;
  List<Attachments>? attachments;

  Records({this.doctorNotes, this.attachments});

  Records.fromJson(Map<String, dynamic> json) {
    if (json['doctor_notes'] != null) {
      doctorNotes = <DoctorNotes>[];
      json['doctor_notes'].forEach((v) {
        doctorNotes!.add(DoctorNotes.fromJson(v));
      });
    }
    if (json['attachments'] != null) {
      attachments = <Attachments>[];
      json['attachments'].forEach((v) {
        attachments!.add(Attachments.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (doctorNotes != null) {
      data['doctor_notes'] = doctorNotes!.map((v) => v.toJson()).toList();
    }
    if (attachments != null) {
      data['attachments'] = attachments!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class DoctorNotes {
  String? noteId;
  String? timestamp;
  String? content;

  DoctorNotes({this.noteId, this.timestamp, this.content});

  DoctorNotes.fromJson(Map<String, dynamic> json) {
    noteId = json['note_id'];
    timestamp = json['timestamp'];
    content = json['content'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['note_id'] = noteId;
    data['timestamp'] = timestamp;
    data['content'] = content;
    return data;
  }
}

class Attachments {
  String? fileId;
  String? name;
  String? url;
  String? date;

  Attachments({this.fileId, this.name, this.url, this.date});

  Attachments.fromJson(Map<String, dynamic> json) {
    fileId = json['file_id'];
    name = json['name'];
    url = json['url'];
    date = json['date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['file_id'] = fileId;
    data['name'] = name;
    data['url'] = url;
    data['date'] = date;
    return data;
  }
}
