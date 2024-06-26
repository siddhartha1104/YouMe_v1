class Message {
  Message({
    required this.told,
    required this.msg,
    required this.read,
    required this.type,
    required this.fromld,
    required this.sent,
  });
  late final String told;
  late final String msg;
  late final String read;
  late final String fromld;
  late final String sent;
  late final Type type;

  Message.fromJson(Map<String, dynamic> json) {
    told = json['told'].toString();
    msg = json['msg'].toString();
    read = json['read'].toString();
    type = json['type'].toString() == Type.image.name ? Type.image : Type.text;
    fromld = json['fromld'].toString();
    sent = json['sent'].toString();
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['told'] = told;
    data['msg'] = msg;
    data['read'] = read;
    data['type'] = type.name;
    data['fromld'] = fromld;
    data['sent'] = sent;
    return data;
  }
}

enum Type { text, image }
