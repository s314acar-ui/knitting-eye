/// İş emri JSON modeli
class WorkOrder {
  final String recipeId;
  final String date;
  final String factory;
  final Order order;
  final Fabric fabric;
  final Machine machine;
  final List<Yarn> yarns;
  final List<String> process;
  final String notes;

  WorkOrder({
    required this.recipeId,
    required this.date,
    required this.factory,
    required this.order,
    required this.fabric,
    required this.machine,
    required this.yarns,
    required this.process,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'recipe_id': recipeId,
      'date': date,
      'factory': factory,
      'order': order.toJson(),
      'fabric': fabric.toJson(),
      'machine': machine.toJson(),
      'yarns': yarns.map((y) => y.toJson()).toList(),
      'process': process,
      'notes': notes,
    };
  }

  factory WorkOrder.empty() {
    return WorkOrder(
      recipeId: '',
      date: '',
      factory: '',
      order: Order.empty(),
      fabric: Fabric.empty(),
      machine: Machine.empty(),
      yarns: [],
      process: [],
      notes: '',
    );
  }
}

class Order {
  final String no;
  final String main;
  final String customer;
  final String delivery;

  Order({
    required this.no,
    required this.main,
    required this.customer,
    required this.delivery,
  });

  Map<String, dynamic> toJson() {
    return {
      'no': no,
      'main': main,
      'customer': customer,
      'delivery': delivery,
    };
  }

  factory Order.empty() {
    return Order(no: '', main: '', customer: '', delivery: '');
  }
}

class Fabric {
  final String name;
  final String type;
  final double totalKg;
  final int pieceCount;
  final double pieceWeightKg;

  Fabric({
    required this.name,
    required this.type,
    required this.totalKg,
    required this.pieceCount,
    required this.pieceWeightKg,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'total_kg': totalKg,
      'piece_count': pieceCount,
      'piece_weight_kg': pieceWeightKg,
    };
  }

  factory Fabric.empty() {
    return Fabric(name: '', type: '', totalKg: 0, pieceCount: 0, pieceWeightKg: 0);
  }
}

class Machine {
  final String id;
  final String type;
  final Gauge gauge;
  final String courseLength;
  final int turnsPerPiece;

  Machine({
    required this.id,
    required this.type,
    required this.gauge,
    required this.courseLength,
    required this.turnsPerPiece,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'gauge': gauge.toJson(),
      'course_length': courseLength,
      'turns_per_piece': turnsPerPiece,
    };
  }

  factory Machine.empty() {
    return Machine(id: '', type: '', gauge: Gauge.empty(), courseLength: '', turnsPerPiece: 0);
  }
}

class Gauge {
  final int puss;
  final int fein;

  Gauge({required this.puss, required this.fein});

  Map<String, dynamic> toJson() {
    return {
      'puss': puss,
      'fein': fein,
    };
  }

  factory Gauge.empty() {
    return Gauge(puss: 0, fein: 0);
  }
}

class Yarn {
  final int seq;
  final String code;
  final String desc;
  final String lot;
  final double qtyKg;
  final double wastePct;
  final double ratioPct;

  Yarn({
    required this.seq,
    required this.code,
    required this.desc,
    required this.lot,
    required this.qtyKg,
    required this.wastePct,
    required this.ratioPct,
  });

  Map<String, dynamic> toJson() {
    return {
      'seq': seq,
      'code': code,
      'desc': desc,
      'lot': lot,
      'qty_kg': qtyKg,
      'waste_pct': wastePct,
      'ratio_pct': ratioPct,
    };
  }
}
