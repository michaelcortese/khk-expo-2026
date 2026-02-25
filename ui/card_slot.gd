extends Button
class_name CardSlot

@onready var icon: TextureRect = $Content/Icon
@onready var name_label: Label = $Content/Name
@onready var cost_label: Label = $CostBadge/Cost

var card_id: String = ""

func set_card(id: String, display_name: String = "", cost: int = 0, tex: Texture2D = null) -> void:
	card_id = id
	if display_name != "":
		name_label.text = display_name
	else:
		name_label.text = id

	cost_label.text = str(cost)

	if tex:
		icon.texture = tex
