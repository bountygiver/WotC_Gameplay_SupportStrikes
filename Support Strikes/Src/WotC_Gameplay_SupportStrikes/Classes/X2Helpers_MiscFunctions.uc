class X2Helpers_MiscFunctions extends Object;

static function GiveItem(name ItemTemplateName, XComGameState_Unit Unit, XComGameState NewGameState)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate ItemTemplate;
	local XGUnit Visualizer;
	local XComGameState_Item Item;
	local XComGameState_Item OldItem;
	local XComGameStateHistory History;
	local XGItem OldItemVisualizer;
	local XComGameState_Player kPlayer;

	local XComGameState_Ability ItemAbility;	
	local int AbilityIndex;
	local array<AbilitySetupData> AbilityData;
	local X2TacticalGameRuleset TacticalRules;

	History = `XCOMHISTORY;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ItemTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(ItemTemplateName));
	if(ItemTemplate == none) return;

	Visualizer = XGUnit(Unit.GetVisualizer());

	Item = ItemTemplate.CreateInstanceFromTemplate(NewGameState);

	//Take away the old item
	if (ItemTemplate.InventorySlot == eInvSlot_PrimaryWeapon ||
		ItemTemplate.InventorySlot == eInvSlot_SecondaryWeapon ||
		ItemTemplate.InventorySlot == eInvSlot_HeavyWeapon)
	{
		OldItem = Unit.GetItemInSlot(ItemTemplate.InventorySlot);
		Unit.RemoveItemFromInventory(OldItem, NewGameState);		

		//Remove abilities that were being granted by the old item
		for( AbilityIndex = Unit.Abilities.Length - 1; AbilityIndex > -1; --AbilityIndex )
		{
			ItemAbility = XComGameState_Ability(History.GetGameStateForObjectID(Unit.Abilities[AbilityIndex].ObjectID));
			if( ItemAbility.SourceWeapon.ObjectID == OldItem.ObjectID )
			{
				Unit.Abilities.Remove(AbilityIndex, 1);
			}
		}
	}

	Unit.bIgnoreItemEquipRestrictions = true; //Instruct the system that we don't care about item restrictions
	Unit.AddItemToInventory(Item, ItemTemplate.InventorySlot, NewGameState);	

	//Give the unit any abilities that this weapon confers
	kPlayer = XComGameState_Player(History.GetGameStateForObjectID(Unit.ControllingPlayer.ObjectID));			
	AbilityData = Unit.GatherUnitAbilitiesForInit(NewGameState, kPlayer);
	TacticalRules = `TACTICALRULES;
	for (AbilityIndex = 0; AbilityIndex < AbilityData.Length; ++AbilityIndex)
	{
		if( AbilityData[AbilityIndex].SourceWeaponRef.ObjectID == Item.ObjectID )
		{
			TacticalRules.InitAbilityForUnit(AbilityData[AbilityIndex].Template, Unit, NewGameState, AbilityData[AbilityIndex].SourceWeaponRef);
		}
	}

	if( OldItem.ObjectID > 0 )
	{
		//Destroy the visuals for the old item if we had one
		OldItemVisualizer = XGItem(History.GetVisualizer(OldItem.ObjectID));
		OldItemVisualizer.Destroy();
		History.SetVisualizer(OldItem.ObjectID, none);
	}
	
	//Create the visualizer for the new item, and attach it if needed
	Visualizer.ApplyLoadoutFromGameState(Unit, NewGameState);
}