//
// FILE:	X2Helper_SpawnUnit
// AUTHOR:	E3245

class X2Helper_SpawnUnit extends Object config(GameData_SupportStrikes);

struct SpawnCharacterData
{
	var name TemplateName;
	var string CharacterPoolName;
	var name WPNCategory;		// GiveItem executes if true for possible primary and secondary weapons
	structdefaultproperties
	{
		CharacterPoolName = "";
	}
};

struct XComDropTrooperData
{
	var bool bSequential;			// If false, it's randomly picked
	var bool bIsPilot;				// Special case for Matinee
	var array<SpawnCharacterData> CharacterTemplate;
	var int MinForceLevel;
	var int MaxForceLevel;
	var int AlertLevel;
	var int MaxUnitsToSpawn;

	structdefaultproperties
	{
		AlertLevel = 0;
		MinForceLevel = 0;
		MaxForceLevel = 0;
		MaxUnitsToSpawn = 0;
	}
};


struct WeaponDataIntermediary 
{
	var name PriWeaponTemplate;
	var name SecWeaponTemplate;
	structdefaultproperties
	{
		PriWeaponTemplate = none;
		SecWeaponTemplate = none;
	}
};

struct RandomWeaponData
{
	var name Category;
	var array<WeaponDataIntermediary> arrWeapons;
};


var config array<XComDropTrooperData>	arrSpawnUnitData;
var config array<RandomWeaponData>		arrRandomWeapons;
var config int							SpawnedUnit_StandardAP;
var config int							SpawnedUnit_MovementOnlyAP;

// Not the best optimization ever in picking the closest Dataset between a range
public static function XComDropTrooperData PickBestDataSet(int ForceLevel, optional bool bIsPilot = false)
{
	local int i;

	`LOG("[PickBestDataSet()] Current force level: " $ ForceLevel $ " and Pilot: " $ bIsPilot,, 'WotC_Gameplay_SupportStrikes');

	for (i = 0; i < default.arrSpawnUnitData.Length; i++)
	{
		//Skip over empty Character Template arrays
		if (default.arrSpawnUnitData[i].CharacterTemplate.Length == 0)
			continue;

		// If we're looking for pilots, do not evaluate anything else
		if (bIsPilot)
		{
			if (default.arrSpawnUnitData[i].bIsPilot)
			{
				`LOG("[PickBestDataSet()] Picked data set at index " $ i,, 'WotC_Gameplay_SupportStrikes');
				return default.arrSpawnUnitData[i];
			}
			else
				continue;
		}

		if ( (ForceLevel >= default.arrSpawnUnitData[i].MinForceLevel) &&
			 (ForceLevel <= default.arrSpawnUnitData[i].MaxForceLevel) )
		{
			`LOG("[PickBestDataSet()] Picked data set at index " $ i,, 'WotC_Gameplay_SupportStrikes');
			return default.arrSpawnUnitData[i];
		}
		else
			`LOG("[PickBestDataSet()] " $ ForceLevel $ " not greater than " $ default.arrSpawnUnitData[i].MinForceLevel $ " and not less than " $ default.arrSpawnUnitData[i].MinForceLevel,, 'WotC_Gameplay_SupportStrikes');

	}
	`LOG("[PickBestDataSet()] ERROR, no dataset was picked!",, 'WotC_Gameplay_SupportStrikes');
}

static function ChangeEquipment(SpawnCharacterData CharTemplate, XComGameState_Unit UnitState, XComGameState NewGameState, bool bIsCineActor)
{
	local WeaponDataIntermediary			WeaponToAdd;
	local int								Idx, AbilityIndex;
	local X2ItemTemplateManager				ItemTemplateManager;
	local X2EquipmentTemplate				ItemTemplate;
	local XComGameState_Item				ItemState;
	local XComGameState_Item				OldItem;
	local XComGameState_Ability				ItemAbility;	
	local XComGameStateHistory				History;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	History = `XCOMHISTORY;

	if (CharTemplate.WPNCategory != '' && default.arrRandomWeapons.Length > 0 && !bIsCineActor)
	{
		Idx = default.arrRandomWeapons.Find('Category', CharTemplate.WPNCategory);
		if (Idx != INDEX_NONE)
		{
			WeaponToAdd = default.arrRandomWeapons[Idx].arrWeapons[ `SYNC_RAND_STATIC(default.arrRandomWeapons[Idx].arrWeapons.Length) ];
			if (WeaponToAdd.PriWeaponTemplate != '')
			{
				ItemTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(WeaponToAdd.PriWeaponTemplate));
				if (ItemTemplate != none)
				{
					//Create our new itemstate
					ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);

					OldItem = UnitState.GetItemInSlot(ItemTemplate.InventorySlot);
					UnitState.RemoveItemFromInventory(OldItem, NewGameState);		

					//Remove abilities that were being granted by the old item
					for( AbilityIndex = UnitState.Abilities.Length - 1; AbilityIndex > -1; --AbilityIndex )
					{
						ItemAbility = XComGameState_Ability(History.GetGameStateForObjectID(UnitState.Abilities[AbilityIndex].ObjectID));
						if( ItemAbility.SourceWeapon.ObjectID == OldItem.ObjectID )
						{
							UnitState.Abilities.Remove(AbilityIndex, 1);
						}
					}
					
					UnitState.bIgnoreItemEquipRestrictions = true; //Instruct the system that we don't care about item restrictions

					// Add it to the inventory
					UnitState.AddItemToInventory(ItemState, ItemTemplate.InventorySlot, NewGameState);

					`LOG("[" $ GetFuncName() $ "] Gave " $ UnitState.GetFullName() $ " a " $ ItemState.GetMyTemplate().FriendlyName,, 'WotC_Strategy_SupportStrikes');
				}
			}
			else
				`LOG("[" $ GetFuncName() $ "] Primary Weapon not specified",, 'WotC_Strategy_SupportStrikes');

			if (WeaponToAdd.SecWeaponTemplate != '')
			{
				ItemTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(WeaponToAdd.PriWeaponTemplate));
				if (ItemTemplate != none)
				{
					//Create our new itemstate
					ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);

					//Remove abilities that were being granted by the old item
					for( AbilityIndex = UnitState.Abilities.Length - 1; AbilityIndex > -1; --AbilityIndex )
					{
						ItemAbility = XComGameState_Ability(History.GetGameStateForObjectID(UnitState.Abilities[AbilityIndex].ObjectID));
						if( ItemAbility.SourceWeapon.ObjectID == OldItem.ObjectID )
						{
							UnitState.Abilities.Remove(AbilityIndex, 1);
						}
					}

					UnitState.bIgnoreItemEquipRestrictions = true; //Instruct the system that we don't care about item restrictions

					// Add it to the inventory
					UnitState.AddItemToInventory(ItemState, ItemTemplate.InventorySlot, NewGameState);

					`LOG("[" $ GetFuncName() $ "] Gave " $ UnitState.GetFullName() $ " a " $ ItemState.GetMyTemplate().FriendlyName,, 'WotC_Strategy_SupportStrikes');
				}
			}
			else
				`LOG("[" $ GetFuncName() $ "] Secondary Weapon not specified",, 'WotC_Strategy_SupportStrikes');
		}
		else
			`LOG("[" $ GetFuncName() $ "] Could not give " $ UnitState.GetFullName() $ " a weapon or item under " $ CharTemplate.WPNCategory,, 'WotC_Strategy_SupportStrikes');
	}
	else
		`LOG("[" $ GetFuncName() $ "] " $ CharTemplate.WPNCategory $ " not specified",, 'WotC_Strategy_SupportStrikes');
}