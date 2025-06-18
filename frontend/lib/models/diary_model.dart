class Diary {
  final int diaryNum;
  // final String userId;
  final dynamic userId;
  final int styleId;
  final DateTime diaryDate;
  final String content;
  final String? emotionTag;
  final String? promptResult;
  final DateTime createdAt;
  final int imgCount;
  final List<String>? cutPaths;
  final String? thumbPath;
  final String? mergedPath;
  final int? toonNum;

  factory Diary.fromJson(Map<String, dynamic> json) {
    return Diary(
      diaryNum:     json['diary_num']      as int,
      userId:       json['user_id']       ,
      styleId:      json['style_id']       as int,
      diaryDate:    DateTime.parse(json['diary_date'] as String),
      content:   json['content'] as String? ?? '',
      emotionTag: json['emotion_tag'] != null ? json['emotion_tag'] as String : null,
      promptResult: json['prompt_result']  as String?,
      // createdAt:    DateTime.parse(json['created_at'] as String),
      createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at']).toLocal()
        : DateTime.now(),
      // imgCount:  (json['img_count'] ?? 0) as int,
      imgCount: int.tryParse('${json['img_count'] ?? 0}') ?? 0,
      cutPaths:     (json['cut_paths'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList(),
      thumbPath:    json['thumb_path']     as String?,      // JSON 의 thumb_path
      mergedPath:   json['merged_path']    as String?,      // JSON 의 merged_path
      toonNum:      json['toon_num']       as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'diary_num':     diaryNum,
        'user_id':       userId,
        'style_id':      styleId,
        'diary_date':    diaryDate.toIso8601String().split('T')[0],
        'content':       content,
        'emotion_tag':   emotionTag,
        'prompt_result': promptResult,
        'created_at':    createdAt.toIso8601String(),
        'img_count':     imgCount,
        'cutPaths':      cutPaths,
        'thumb_path':    thumbPath,
        'merged_path':   mergedPath,
        'toon_num':      toonNum,
      };

  const Diary({
    required this.diaryNum,
    required this.userId,
    required this.styleId,
    required this.diaryDate,
    required this.content,
    this.emotionTag,
    this.promptResult,
    required this.createdAt,
    required this.imgCount,
    this.cutPaths,
    this.thumbPath,
    this.mergedPath,
    this.toonNum,
  });
}
