import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Job listing type
enum JobType { fullTime, partTime, contract, freelance, internship }

/// Job status
enum JobStatus { open, closed, filled, draft }

/// Job model for career opportunities in combat sports
class JobModel extends Equatable {
  final String id;
  final String postedById;
  final String postedByType; // gym, promoter, sponsor
  final String title;
  final String description;
  final JobType jobType;
  final JobStatus status;
  final String? gymId;
  final String? promoterId;
  final String? sponsorId;
  final String? location;
  final bool isRemote;
  final String? salaryMin;
  final String? salaryMax;
  final String? currency;
  final String? salaryPeriod; // hourly, weekly, monthly, yearly
  final List<String> requirements;
  final List<String> benefits;
  final List<String> responsibilities;
  final List<String> skills;
  final String? experienceLevel; // entry, mid, senior
  final String? category; // coaching, management, marketing, etc.
  final DateTime? applicationDeadline;
  final int applicationsCount;
  final int viewsCount;
  final bool isFeatured;
  final Map<String, dynamic>? contactInfo;
  final String? applicationUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JobModel({
    required this.id,
    required this.postedById,
    required this.postedByType,
    required this.title,
    required this.description,
    this.jobType = JobType.fullTime,
    this.status = JobStatus.open,
    this.gymId,
    this.promoterId,
    this.sponsorId,
    this.location,
    this.isRemote = false,
    this.salaryMin,
    this.salaryMax,
    this.currency,
    this.salaryPeriod,
    this.requirements = const [],
    this.benefits = const [],
    this.responsibilities = const [],
    this.skills = const [],
    this.experienceLevel,
    this.category,
    this.applicationDeadline,
    this.applicationsCount = 0,
    this.viewsCount = 0,
    this.isFeatured = false,
    this.contactInfo,
    this.applicationUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Is job still accepting applications
  bool get isAcceptingApplications {
    if (status != JobStatus.open) return false;
    if (applicationDeadline == null) return true;
    return DateTime.now().isBefore(applicationDeadline!);
  }

  /// Has salary information
  bool get hasSalaryInfo => salaryMin != null || salaryMax != null;

  /// Salary range display string
  String? get salaryRange {
    if (!hasSalaryInfo) return null;
    final curr = currency ?? 'AUD';
    if (salaryMin != null && salaryMax != null) {
      return '$curr $salaryMin - $salaryMax ${salaryPeriod ?? ''}';
    }
    if (salaryMin != null) return 'From $curr $salaryMin ${salaryPeriod ?? ''}';
    if (salaryMax != null) {
      return 'Up to $curr $salaryMax ${salaryPeriod ?? ''}';
    }
    return null;
  }

  factory JobModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobModel(
      id: doc.id,
      postedById: data['postedById'] ?? '',
      postedByType: data['postedByType'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      jobType: JobType.values.firstWhere(
        (t) => t.name == data['jobType'],
        orElse: () => JobType.fullTime,
      ),
      status: JobStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => JobStatus.open,
      ),
      gymId: data['gymId'],
      promoterId: data['promoterId'],
      sponsorId: data['sponsorId'],
      location: data['location'],
      isRemote: data['isRemote'] ?? false,
      salaryMin: data['salaryMin'],
      salaryMax: data['salaryMax'],
      currency: data['currency'],
      salaryPeriod: data['salaryPeriod'],
      requirements: List<String>.from(data['requirements'] ?? []),
      benefits: List<String>.from(data['benefits'] ?? []),
      responsibilities: List<String>.from(data['responsibilities'] ?? []),
      skills: List<String>.from(data['skills'] ?? []),
      experienceLevel: data['experienceLevel'],
      category: data['category'],
      applicationDeadline: (data['applicationDeadline'] as Timestamp?)
          ?.toDate(),
      applicationsCount: data['applicationsCount'] ?? 0,
      viewsCount: data['viewsCount'] ?? 0,
      isFeatured: data['isFeatured'] ?? false,
      contactInfo: data['contactInfo'],
      applicationUrl: data['applicationUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postedById': postedById,
      'postedByType': postedByType,
      'title': title,
      'description': description,
      'jobType': jobType.name,
      'status': status.name,
      'gymId': gymId,
      'promoterId': promoterId,
      'sponsorId': sponsorId,
      'location': location,
      'isRemote': isRemote,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'currency': currency,
      'salaryPeriod': salaryPeriod,
      'requirements': requirements,
      'benefits': benefits,
      'responsibilities': responsibilities,
      'skills': skills,
      'experienceLevel': experienceLevel,
      'category': category,
      'applicationDeadline': applicationDeadline != null
          ? Timestamp.fromDate(applicationDeadline!)
          : null,
      'applicationsCount': applicationsCount,
      'viewsCount': viewsCount,
      'isFeatured': isFeatured,
      'contactInfo': contactInfo,
      'applicationUrl': applicationUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  JobModel copyWith({
    String? id,
    String? postedById,
    String? postedByType,
    String? title,
    String? description,
    JobType? jobType,
    JobStatus? status,
    String? gymId,
    String? promoterId,
    String? sponsorId,
    String? location,
    bool? isRemote,
    String? salaryMin,
    String? salaryMax,
    String? currency,
    String? salaryPeriod,
    List<String>? requirements,
    List<String>? benefits,
    List<String>? responsibilities,
    List<String>? skills,
    String? experienceLevel,
    String? category,
    DateTime? applicationDeadline,
    int? applicationsCount,
    int? viewsCount,
    bool? isFeatured,
    Map<String, dynamic>? contactInfo,
    String? applicationUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobModel(
      id: id ?? this.id,
      postedById: postedById ?? this.postedById,
      postedByType: postedByType ?? this.postedByType,
      title: title ?? this.title,
      description: description ?? this.description,
      jobType: jobType ?? this.jobType,
      status: status ?? this.status,
      gymId: gymId ?? this.gymId,
      promoterId: promoterId ?? this.promoterId,
      sponsorId: sponsorId ?? this.sponsorId,
      location: location ?? this.location,
      isRemote: isRemote ?? this.isRemote,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      currency: currency ?? this.currency,
      salaryPeriod: salaryPeriod ?? this.salaryPeriod,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      responsibilities: responsibilities ?? this.responsibilities,
      skills: skills ?? this.skills,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      category: category ?? this.category,
      applicationDeadline: applicationDeadline ?? this.applicationDeadline,
      applicationsCount: applicationsCount ?? this.applicationsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      isFeatured: isFeatured ?? this.isFeatured,
      contactInfo: contactInfo ?? this.contactInfo,
      applicationUrl: applicationUrl ?? this.applicationUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, status, postedById];
}

/// Job application model
class JobApplicationModel extends Equatable {
  final String id;
  final String jobId;
  final String applicantId;
  final String coverLetter;
  final String? resumeUrl;
  final String status; // pending, reviewing, shortlisted, rejected, hired
  final String? notes;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JobApplicationModel({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.coverLetter,
    this.resumeUrl,
    this.status = 'pending',
    this.notes,
    this.reviewedAt,
    this.reviewedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JobApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobApplicationModel(
      id: doc.id,
      jobId: data['jobId'] ?? '',
      applicantId: data['applicantId'] ?? '',
      coverLetter: data['coverLetter'] ?? '',
      resumeUrl: data['resumeUrl'],
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'jobId': jobId,
      'applicantId': applicantId,
      'coverLetter': coverLetter,
      'resumeUrl': resumeUrl,
      'status': status,
      'notes': notes,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [id, jobId, applicantId, status];
}
