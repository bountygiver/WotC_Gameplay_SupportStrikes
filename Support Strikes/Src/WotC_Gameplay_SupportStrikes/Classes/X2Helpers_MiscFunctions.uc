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

// Repurposed TeleportToCursor Cheat function
static function TeleportUnitState(XComGameState_Unit ActiveUnit, Vector vLoc, optional bool bNoStateSubmission = false)
{
	local XComGameState				TeleportGameState;
	local TTile						UnitTile;
	local XComWorldData				WorldData;
//	local int						i;
//	local array<vector>				FloorPoints;
//	local vector					FinalPos;

	WorldData = `XWORLD;

	if (ActiveUnit != none)
	{	
		// If this comes from somewhere that doesn't have an effect, then this path should be used
		if (!bNoStateSubmission)
		{
			TeleportGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Helper: Teleport Unit" );
			XComGameStateContext_ChangeContainer( TeleportGameState.GetContext() ).BuildVisualizationFn = `CHEATMGR.CheatTeleport_BuildVisualization;
			ActiveUnit = XComGameState_Unit(TeleportGameState.ModifyStateObject(class'XComGameState_Unit', ActiveUnit.ObjectID));
		}

		ActiveUnit.bRequiresVisibilityUpdate = true;
		
		UnitTile = WorldData.GetTileCoordinatesFromPosition(vLoc);
		UnitTile = class'Helpers'.static.GetClosestValidTile(UnitTile);

/*
		if( !World.CanUnitsEnterTile(UnitTile) )
		{
			WorldData.GetFloorTilePositions(vLoc, World.WORLD_StepSize * 4, World.WORLD_StepSize, FloorPoints, true);

			i = 0;
			while( i < FloorPoints.Length )
			{
				FinalPos = FloorPoints[i];
				UnitTile = World.GetTileCoordinatesFromPosition(FinalPos);
				if( World.CanUnitsEnterTile(SelectedTile) )
				{
					// Found a valid landing location
					i = FloorPoints.Length;
				}

				++i;
			}
		}
*/
		ActiveUnit.SetVisibilityLocation(UnitTile);
	
		if (!bNoStateSubmission)
			`TACTICALRULES.SubmitGameState(TeleportGameState);
	}
}