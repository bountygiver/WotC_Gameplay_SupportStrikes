class X2StrategyElement_CovertActions_SupportStrikes extends X2StrategyElement_DefaultCovertActions config(GameData);

struct CovertActionSlotStruct
{
	var name StaffSlotTemplateName;
	var int MinRank;
	var bool bOptional;
	var bool bRandomClass;
	var bool bFactionClass;
	var bool bChanceFame;
	var bool bReduceRisk;
	structdefaultproperties
	{
		StaffSlotTemplateName=none;
		MinRank=0;
		bOptional=false;
		bRandomClass=false;
		bFactionClass=false;
		bChanceFame=false;
		bReduceRisk=false;
	}
};

struct OptionalCostStruct
{
	var name ResourceTemplateName;
	var int Quantity;
	structdefaultproperties
	{
		ResourceTemplateName=none;
		Quantity=0;
	}
};

var config array<CovertActionSlotStruct> StaffSlots;
var config array<OptionalCostStruct> OptionalCosts;
var config array<name> Risks;
var config array<name> SoldierSlotFilter;
var config array<name> StaffSlotFilter;
/*
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> CovertActions;

	CovertActions.AddItem(CreatePrisonBreakMissionTemplate());

	return CovertActions;
}

//---------------------------------------------------------------------------------------
// PRISON BREAK
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePrisonBreakMissionTemplate()
{
	local X2CovertActionTemplate Template;
	local int i;

	`CREATE_X2TEMPLATE(class'X2CovertActionTemplate', Template, 'CovertAction_PrisonBreakMission');

	Template.ChooseLocationFn = ChooseRandomRivalChosenRegion;
	Template.OverworldMeshPath = "UI_3D.Overwold_Final.CovertAction";
	Template.bMultiplesAllowed = false;

	Template.Narratives.AddItem('CovertActionNarrative_PrisonBreakMission_Skirmishers');
	Template.Narratives.AddItem('CovertActionNarrative_PrisonBreakMission_Reapers');
	Template.Narratives.AddItem('CovertActionNarrative_PrisonBreakMission_Templars');
	for (i = 0; i < default.StaffSlots.Length; i++)
	{
		if ((default.SoldierSlotFilter.Find(default.StaffSlots[i].StaffSlotTemplateName)) != INDEX_NONE)
		{
			if (default.StaffSlots[i].bOptional) 
			{
				Template.Slots.AddItem(CreateDefaultOptionalSlot(default.StaffSlots[i].StaffSlotTemplateName, 
				default.StaffSlots[i].MinRank,  
				default.StaffSlots[i].bFactionClass));
			}
			else
			{
				Template.Slots.AddItem(CreateDefaultSoldierSlot(default.StaffSlots[i].StaffSlotTemplateName, 
				default.StaffSlots[i].MinRank, 
				default.StaffSlots[i].bRandomClass, 
				default.StaffSlots[i].bFactionClass,
				default.StaffSlots[i].bChanceFame,
				default.StaffSlots[i].bReduceRisk));
			}
		}
		else if (default.StaffSlotFilter.Find(default.StaffSlots[i].StaffSlotTemplateName) != INDEX_NONE)
		{
			Template.Slots.AddItem(CreateDefaultStaffSlot(default.StaffSlots[i].StaffSlotTemplateName));
		}
	}

	for (i = 0; i < default.OptionalCosts.Length; i++)
		Template.OptionalCosts.AddItem(CreateOptionalCostSlot(default.OptionalCosts[i].ResourceTemplateName, default.OptionalCosts[i].Quantity));

	//Now add risks
	for (i = 0; i < default.Risks.Length; i++)
		Template.Risks.AddItem(default.Risks[i]);

	Template.Rewards.AddItem('Reward_Mission_PrisonBreakRescue');

	return Template;
}


//
// IMPORTANT HELPER FUNCTIONS
// ---------------------------------------------------------------------------
private static function CovertActionSlot CreateDefaultSoldierSlot(name SlotName, optional int iMinRank, optional bool bRandomClass, optional bool bFactionClass, optional bool bFameChance, optional bool bReduceRisk)
{
	local CovertActionSlot SoldierSlot;

	SoldierSlot.StaffSlot = SlotName;
	SoldierSlot.Rewards.AddItem('Reward_StatBoostHP');
	SoldierSlot.Rewards.AddItem('Reward_StatBoostAim');
	SoldierSlot.Rewards.AddItem('Reward_StatBoostMobility');
	SoldierSlot.Rewards.AddItem('Reward_StatBoostDodge');
	SoldierSlot.Rewards.AddItem('Reward_StatBoostWill');
	SoldierSlot.Rewards.AddItem('Reward_StatBoostHacking');
	SoldierSlot.Rewards.AddItem('Reward_RankUp');
	SoldierSlot.iMinRank = iMinRank;
	SoldierSlot.bChanceFame = bFameChance;
	SoldierSlot.bRandomClass = bRandomClass;
	SoldierSlot.bFactionClass = bFactionClass;
	SoldierSlot.bReduceRisk = bReduceRisk;

	if (SlotName == 'CovertActionRookieStaffSlot')
	{
		SoldierSlot.bChanceFame = false;
	}

	return SoldierSlot;
}

private static function CovertActionSlot CreateDefaultStaffSlot(name SlotName)
{
	local CovertActionSlot StaffSlot;
	
	// Same as Soldier Slot, but no rewards
	StaffSlot.StaffSlot = SlotName;
	StaffSlot.bReduceRisk = false;
	
	return StaffSlot;
}

private static function CovertActionSlot CreateDefaultOptionalSlot(name SlotName, optional int iMinRank, optional bool bFactionClass)
{
	local CovertActionSlot OptionalSlot;

	OptionalSlot.StaffSlot = SlotName;
	OptionalSlot.bChanceFame = false;
	OptionalSlot.bReduceRisk = true;
	OptionalSlot.iMinRank = iMinRank;
	OptionalSlot.bFactionClass = bFactionClass;

	return OptionalSlot;
}
*/
private static function StrategyCostReward CreateOptionalCostSlot(name ResourceName, int Quantity)
{
	local StrategyCostReward ActionCost;
	local ArtifactCost Resources;

	Resources.ItemTemplateName = ResourceName;
	Resources.Quantity = Quantity;
	ActionCost.Cost.ResourceCosts.AddItem(Resources);
	ActionCost.Reward = 'Reward_DecreaseRisk';
	
	return ActionCost;
}
