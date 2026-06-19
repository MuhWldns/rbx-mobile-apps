class ProductCategory {
  final String id;
  final String name;
  final String slug;

  ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}

class Product {
  final String id;
  final String name;
  final String slug;
  final String? shortDesc;
  final String? thumbnail;
  final int pricePersonal;
  final int priceCommercial;
  final int priceEnterprise;
  final bool featured;
  final String? version;
  final List<String> tags;
  final ProductCategory? category;
  final String? image;
  final int soldCount;
  final String? createdAt;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    this.shortDesc,
    this.thumbnail,
    required this.pricePersonal,
    required this.priceCommercial,
    required this.priceEnterprise,
    required this.featured,
    this.version,
    required this.tags,
    this.category,
    this.image,
    required this.soldCount,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      shortDesc: json['shortDesc'],
      thumbnail: json['thumbnail'],
      pricePersonal: json['pricePersonal'] ?? 0,
      priceCommercial: json['priceCommercial'] ?? 0,
      priceEnterprise: json['priceEnterprise'] ?? 0,
      featured: json['featured'] ?? false,
      version: json['version'],
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'] != null
          ? ProductCategory.fromJson(json['category'])
          : null,
      image: json['image'],
      soldCount: json['soldCount'] ?? 0,
      createdAt: json['createdAt'],
    );
  }
}
