/// Model Data Buku yang kompatibel dengan skema JSON Google Books API v1
/// Endpoint Referensi: https://www.googleapis.com/books/v1/volumes
class BookVolumeResponse {
  final String kind;
  final int totalItems;
  final String apiEndpoint;
  final List<BookVolume> items;

  const BookVolumeResponse({
    required this.kind,
    required this.totalItems,
    required this.apiEndpoint,
    required this.items,
  });

  factory BookVolumeResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return BookVolumeResponse(
      kind: json['kind'] as String? ?? 'books#volumes',
      totalItems: (json['totalItems'] as num?)?.toInt() ?? rawItems.length,
      apiEndpoint: json['apiEndpoint'] as String? ??
          'https://www.googleapis.com/books/v1/volumes',
      items: rawItems
          .map((e) => BookVolume.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BookVolume {
  final String kind;
  final String id;
  final String etag;
  final String selfLink;
  final VolumeInfo volumeInfo;
  final ReadingState readingState;

  const BookVolume({
    required this.kind,
    required this.id,
    required this.etag,
    required this.selfLink,
    required this.volumeInfo,
    required this.readingState,
  });

  factory BookVolume.fromJson(Map<String, dynamic> json) {
    return BookVolume(
      kind: json['kind'] as String? ?? 'books#volume',
      id: json['id'] as String? ?? '',
      etag: json['etag'] as String? ?? '',
      selfLink: json['selfLink'] as String? ?? '',
      volumeInfo: VolumeInfo.fromJson(
        json['volumeInfo'] as Map<String, dynamic>? ?? const {},
      ),
      readingState: ReadingState.fromJson(
        json['readingState'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  /// Factory untuk mem-parsing volume langsung dari respons Google Books API v1
  factory BookVolume.fromGoogleApiJson(
    Map<String, dynamic> json, {
    String fallbackCategory = 'Computer Science',
  }) {
    final vInfo = json['volumeInfo'] as Map<String, dynamic>? ?? const {};
    final id = json['id'] as String? ?? '';
    final etag = json['etag'] as String? ?? '';
    final selfLink = json['selfLink'] as String? ?? '';

    final parsedVolumeInfo = VolumeInfo.fromJson(vInfo);
    final effectiveCategories = parsedVolumeInfo.categories.isEmpty ||
            parsedVolumeInfo.categories.first == 'General'
        ? [fallbackCategory]
        : parsedVolumeInfo.categories;

    final volumeInfo = VolumeInfo(
      title: parsedVolumeInfo.title,
      subtitle: parsedVolumeInfo.subtitle,
      authors: parsedVolumeInfo.authors,
      publisher: parsedVolumeInfo.publisher,
      publishedDate: parsedVolumeInfo.publishedDate,
      description: parsedVolumeInfo.description.isNotEmpty
          ? parsedVolumeInfo.description
          : 'Monograf komprehensif mengenai ${parsedVolumeInfo.title} yang diterbitkan oleh ${parsedVolumeInfo.publisher}. Karya ini menyajikan eksplorasi teoritis dan praktis yang relevan bagi pembaca dan akademisi.',
      industryIdentifiers: parsedVolumeInfo.industryIdentifiers,
      pageCount: parsedVolumeInfo.pageCount > 0 ? parsedVolumeInfo.pageCount : 280,
      categories: effectiveCategories,
      averageRating: parsedVolumeInfo.averageRating > 0 ? parsedVolumeInfo.averageRating : 4.7,
      ratingsCount: parsedVolumeInfo.ratingsCount > 0 ? parsedVolumeInfo.ratingsCount : 120,
      language: parsedVolumeInfo.language,
      imageLinks: parsedVolumeInfo.imageLinks,
      previewLink: parsedVolumeInfo.previewLink,
    );

    final palette = _paletteForCategory(effectiveCategories.first);

    final readingState = ReadingState(
      isBookmarked: false,
      isTrending: true,
      isEditorPick: false,
      currentPage: 0,
      lastReadAt: 0,
      coverHex: palette.$1,
      accentHex: palette.$2,
      authorBio:
          '${volumeInfo.primaryAuthor} adalah penulis dan pakar di bidang ${volumeInfo.primaryCategory}.',
      keyTakeaways: [
        'Eksplorasi mendalam konsep fundamental ${volumeInfo.title}.',
        'Analisis praktis yang teruji pada skala riil dan relevan dengan industri.',
        'Prinsip terstruktur untuk implementasi dan pemikiran berkelanjutan.'
      ],
      sampleExcerpt: 'Bab 1 — Fondasi & Gagasan Utama\n\n${volumeInfo.description}',
    );

    return BookVolume(
      kind: json['kind'] as String? ?? 'books#volume',
      id: id,
      etag: etag,
      selfLink: selfLink,
      volumeInfo: volumeInfo,
      readingState: readingState,
    );
  }

  static (String, String) _paletteForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('computer') || lower.contains('tech') || lower.contains('code')) {
      return ('#28463B', '#EDE8DF');
    } else if (lower.contains('psychology') || lower.contains('mind')) {
      return ('#8C3B32', '#F6F3EC');
    } else if (lower.contains('self') || lower.contains('growth') || lower.contains('habit')) {
      return ('#4A6B53', '#EAE3D5');
    } else if (lower.contains('fiction') || lower.contains('novel') || lower.contains('story')) {
      return ('#A64B2A', '#FCFBF8');
    }
    return ('#1C1917', '#EDE8DF');
  }

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'id': id,
        'etag': etag,
        'selfLink': selfLink,
        'volumeInfo': volumeInfo.toJson(),
        'readingState': readingState.toJson(),
      };

  BookVolume copyWith({
    VolumeInfo? volumeInfo,
    ReadingState? readingState,
  }) {
    return BookVolume(
      kind: kind,
      id: id,
      etag: etag,
      selfLink: selfLink,
      volumeInfo: volumeInfo ?? this.volumeInfo,
      readingState: readingState ?? this.readingState,
    );
  }

  /// Helper untuk menghitung persentase progres baca (0.0 - 1.0)
  double get progressRatio {
    if (volumeInfo.pageCount <= 0) return 0.0;
    final ratio = readingState.currentPage / volumeInfo.pageCount;
    return ratio.clamp(0.0, 1.0);
  }

  int get progressPercent => (progressRatio * 100).round();
}

class VolumeInfo {
  final String title;
  final String subtitle;
  final List<String> authors;
  final String publisher;
  final String publishedDate;
  final String description;
  final List<IndustryIdentifier> industryIdentifiers;
  final int pageCount;
  final List<String> categories;
  final double averageRating;
  final int ratingsCount;
  final String language;
  final ImageLinks imageLinks;
  final String previewLink;

  const VolumeInfo({
    required this.title,
    required this.subtitle,
    required this.authors,
    required this.publisher,
    required this.publishedDate,
    required this.description,
    required this.industryIdentifiers,
    required this.pageCount,
    required this.categories,
    required this.averageRating,
    required this.ratingsCount,
    required this.language,
    required this.imageLinks,
    required this.previewLink,
  });

  factory VolumeInfo.fromJson(Map<String, dynamic> json) {
    final rawAuthors = json['authors'] as List<dynamic>? ?? const ['Anonim'];
    final rawCategories =
        json['categories'] as List<dynamic>? ?? const ['General'];
    final rawIds = json['industryIdentifiers'] as List<dynamic>? ?? const [];

    return VolumeInfo(
      title: json['title'] as String? ?? 'Tanpa Judul',
      subtitle: json['subtitle'] as String? ?? '',
      authors: rawAuthors.map((e) => e.toString()).toList(),
      publisher: json['publisher'] as String? ?? 'Penerbit Independen',
      publishedDate: json['publishedDate'] as String? ?? '2024',
      description: json['description'] as String? ?? '',
      industryIdentifiers: rawIds
          .map((e) => IndustryIdentifier.fromJson(e as Map<String, dynamic>))
          .toList(),
      pageCount: (json['pageCount'] as num?)?.toInt() ?? 200,
      categories: rawCategories.map((e) => e.toString()).toList(),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 4.5,
      ratingsCount: (json['ratingsCount'] as num?)?.toInt() ?? 100,
      language: (json['language'] as String? ?? 'ID').toUpperCase(),
      imageLinks: ImageLinks.fromJson(
        json['imageLinks'] as Map<String, dynamic>? ?? const {},
      ),
      previewLink: json['previewLink'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'authors': authors,
        'publisher': publisher,
        'publishedDate': publishedDate,
        'description': description,
        'industryIdentifiers':
            industryIdentifiers.map((e) => e.toJson()).toList(),
        'pageCount': pageCount,
        'categories': categories,
        'averageRating': averageRating,
        'ratingsCount': ratingsCount,
        'language': language,
        'imageLinks': imageLinks.toJson(),
        'previewLink': previewLink,
      };

  String get primaryAuthor =>
      authors.isNotEmpty ? authors.join(', ') : 'Penulis Tidak Diketahui';

  String get authorsLine => primaryAuthor;

  String get primaryCategory =>
      categories.isNotEmpty ? categories.first : 'Umum';

  String get publishedYear =>
      publishedDate.length >= 4 ? publishedDate.substring(0, 4) : publishedDate;

  String get isbn13 {
    for (final item in industryIdentifiers) {
      if (item.type == 'ISBN_13') return item.identifier;
    }
    return industryIdentifiers.isNotEmpty
        ? industryIdentifiers.first.identifier
        : '978-0000000000';
  }
}

class IndustryIdentifier {
  final String type;
  final String identifier;

  const IndustryIdentifier({
    required this.type,
    required this.identifier,
  });

  factory IndustryIdentifier.fromJson(Map<String, dynamic> json) {
    return IndustryIdentifier(
      type: json['type'] as String? ?? 'ISBN_13',
      identifier: json['identifier'] as String? ?? '-',
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'identifier': identifier,
      };
}

class ImageLinks {
  final String smallThumbnail;
  final String thumbnail;

  const ImageLinks({
    required this.smallThumbnail,
    required this.thumbnail,
  });

  static String _ensureHttps(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http://')) {
      return 'https://${url.substring(7)}';
    }
    return url;
  }

  factory ImageLinks.fromJson(Map<String, dynamic> json) {
    final rawSmall = json['smallThumbnail'] as String? ?? '';
    final rawThumb = (json['thumbnail'] as String?) ??
        (json['small'] as String?) ??
        rawSmall;

    return ImageLinks(
      smallThumbnail: _ensureHttps(rawSmall),
      thumbnail: _ensureHttps(rawThumb),
    );
  }

  Map<String, dynamic> toJson() => {
        'smallThumbnail': smallThumbnail,
        'thumbnail': thumbnail,
      };
}

class ReadingState {
  final bool isBookmarked;
  final bool isTrending;
  final bool isEditorPick;
  final int currentPage;
  final int lastReadAt;
  final String coverHex;
  final String accentHex;
  final String authorBio;
  final List<String> keyTakeaways;
  final String sampleExcerpt;

  bool get isSaved => isBookmarked;

  const ReadingState({
    required this.isBookmarked,
    required this.isTrending,
    required this.isEditorPick,
    required this.currentPage,
    this.lastReadAt = 0,
    required this.coverHex,
    required this.accentHex,
    required this.authorBio,
    required this.keyTakeaways,
    required this.sampleExcerpt,
  });

  factory ReadingState.fromJson(Map<String, dynamic> json) {
    final rawTakeaways = json['keyTakeaways'] as List<dynamic>? ?? const [];
    return ReadingState(
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      isTrending: json['isTrending'] as bool? ?? false,
      isEditorPick: json['isEditorPick'] as bool? ?? false,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 0,
      lastReadAt: (json['lastReadAt'] as num?)?.toInt() ?? 0,
      coverHex: json['coverHex'] as String? ?? '#2A5C4D',
      accentHex: json['accentHex'] as String? ?? '#E8F0EC',
      authorBio: json['authorBio'] as String? ?? '',
      keyTakeaways: rawTakeaways.map((e) => e.toString()).toList(),
      sampleExcerpt: json['sampleExcerpt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'isBookmarked': isBookmarked,
        'isTrending': isTrending,
        'isEditorPick': isEditorPick,
        'currentPage': currentPage,
        'lastReadAt': lastReadAt,
        'coverHex': coverHex,
        'accentHex': accentHex,
        'authorBio': authorBio,
        'keyTakeaways': keyTakeaways,
        'sampleExcerpt': sampleExcerpt,
      };

  ReadingState copyWith({
    bool? isBookmarked,
    int? currentPage,
    int? lastReadAt,
  }) {
    return ReadingState(
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isTrending: isTrending,
      isEditorPick: isEditorPick,
      currentPage: currentPage ?? this.currentPage,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      coverHex: coverHex,
      accentHex: accentHex,
      authorBio: authorBio,
      keyTakeaways: keyTakeaways,
      sampleExcerpt: sampleExcerpt,
    );
  }
}
