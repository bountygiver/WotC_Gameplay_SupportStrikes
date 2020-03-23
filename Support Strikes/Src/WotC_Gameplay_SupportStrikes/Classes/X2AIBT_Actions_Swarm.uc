class X2AIBT_Actions_Swarm extends X2AIBTDefaultActions;

//
// Grabs the destination that the player inputted for an ability
//
function bt_status SetDestinationFromAbility()
{
	local TTile Tile;
	local XComWorldData World;
	local vector Destination;

	World = `XWORLD;

	// Get the closest location from the desired destination
	if( m_kUnitState.CanTakeCover() 
	   && m_kBehavior.GetClosestCoverLocation(GetAbilityContextLocation(), Destination))
	{
		Tile = World.GetTileCoordinatesFromPosition(Destination);
	}

	// Find a tile that's reachable but not on the XCGS_Unit's location
	if( m_kBehavior.m_kUnit.m_kReachableTilesCache.IsTileReachable(Tile) && Tile != m_kUnitState.TileLocation )
	{
		m_kBehavior.m_vBTDestination = World.GetPositionFromTileCoordinates(Tile);
		m_kBehavior.m_bBTDestinationSet = true;
		return BTS_SUCCESS;
	}

	return BTS_FAILURE;
}

//
// For the swarm abilities that requires an input from the ability, try grabbing that very input and returning the vector
// 1) Grab the current player's turn
// 2) Grab the input context that matches our ability template name
// 3) Return the vector associated with the ability context
//
private static function Vector GetAbilityContextLocation()
{
	local XComGameStateContext_Ability			AbilityContext;
	local XComGameStateContext_TacticalGameRule	RuleContext;
	local XComGameStateHistory					History;

	History = `XCOMHISTORY;

	// find the end of the current player turn
	foreach History.IterateContextsByClassType(class'XComGameStateContext_TacticalGameRule', RuleContext)
	{
		if(RuleContext.GameRuleType == eGameRule_PlayerTurnEnd)
		{
			// We need to iterate through the ability contexts made
			foreach History.IterateContextsByClassType(class'XComGameStateContext_Ability', AbilityContext,, true)
			{
				if (AbilityContext.InputContext.AbilityTemplateName == 'Ability_Signal_Swarm_MovePassive')
					return AbilityContext.InputContext.TargetLocations[0];
			}
		}
	}
	//No vector was found, so return 0,0,0
	`LOG("[GetAbilityContextLocation()] AI tree was called but no ability context exists! Report to E3245 if you see this bug!",,'WotC_Gameplay_SupportStrikes');
	return vect(0,0,0);
}