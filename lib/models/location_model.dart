class Province {
  final int id;
  final String name;
  final String? region;
  final String? imageUrl;

  Province({
    required this.id,
    required this.name,
    this.region,
    this.imageUrl,
  });

  factory Province.fromMap(Map<String, dynamic> map) {
    return Province(
      id: map['id'],
      name: map['name'],
      region: map['region'],
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'region': region,
      'imageUrl': imageUrl,
    };
  }
}

class District {
  final int id;
  final String name;
  final int provinceId;

  District({
    required this.id,
    required this.name,
    required this.provinceId,
  });

  factory District.fromMap(Map<String, dynamic> map) {
    return District(
      id: map['id'],
      name: map['name'],
      provinceId: map['provinceId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'provinceId': provinceId,
    };
  }
}
