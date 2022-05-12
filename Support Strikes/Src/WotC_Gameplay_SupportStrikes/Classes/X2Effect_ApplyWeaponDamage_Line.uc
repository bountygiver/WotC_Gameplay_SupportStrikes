class X2Effect_ApplyWeaponDamage_Line extends X2Effect_ApplyWeaponDamage;

simulated function ApplyEffectToWorld(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_EnvironmentDamage DamageEvent;
	local XComGameState_Ability AbilityStateObject;
	local XComGameState_Unit SourceStateObject;
	local XComGameState_Item SourceItemStateObject;
	local X2WeaponTemplate WeaponTemplate;
	local vector DamageDirection;
	local XComGameStateContext_Ability AbilityContext;
	local int DamageAmount;
	local int PhysicalImpulseAmount;
	local name DamageTypeTemplateName;
	local X2AbilityTemplate AbilityTemplate;	
	local XComGameState_Item LoadedAmmo, SourceAmmo;	
	local Vector HitLocation;	
	local bool bLinearDamage;
	local X2AbilityMultiTargetStyle TargetStyle;

	// Variable for Issue #200
	local XComLWTuple ModifyEnvironmentDamageTuple;

	//If this damage effect has an associated position, it does world damage
	if( ApplyEffectParameters.AbilityInputContext.TargetLocations.Length > 0 || ApplyEffectParameters.AbilityResultContext.ProjectileHitLocations.Length > 0 )
	{
		History = `XCOMHISTORY;
		SourceStateObject = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		SourceItemStateObject = XComGameState_Item(History.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));	
		if (SourceItemStateObject != None)
			WeaponTemplate = X2WeaponTemplate(SourceItemStateObject.GetMyTemplate());
		AbilityStateObject = XComGameState_Ability(History.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());

		if( (SourceStateObject != none && AbilityStateObject != none) && (SourceItemStateObject != none || EnvironmentalDamageAmount > 0) )
		{	
			AbilityTemplate = AbilityStateObject.GetMyTemplate();
			if( AbilityTemplate != None )
			{
				TargetStyle = AbilityTemplate.AbilityMultiTargetStyle;

				if( TargetStyle != none && TargetStyle.IsA('X2AbilityMultiTarget_Line') )
				{
					bLinearDamage = true;
				}
			}

            // Calculate the Damage Direction from the Target Location
            DamageDirection = ApplyEffectParameters.AbilityInputContext.TargetLocations[0] - `XWORLD.GetPositionFromTileCoordinates(SourceStateObject.TileLocation);
			
			DamageAmount = EnvironmentalDamageAmount;
			if ((SourceItemStateObject != none) && !bIgnoreBaseDamage)
			{
				SourceAmmo = AbilityStateObject.GetSourceAmmo();
				if (SourceAmmo != none)
				{
					DamageAmount += SourceAmmo.GetItemEnvironmentDamage();
				}
				else if(SourceItemStateObject.HasLoadedAmmo())
				{
					LoadedAmmo = XComGameState_Item(History.GetGameStateForObjectID(SourceItemStateObject.LoadedAmmo.ObjectID));
					if(LoadedAmmo != None)
					{	
						DamageAmount += LoadedAmmo.GetItemEnvironmentDamage();
					}
				}
				
				DamageAmount += SourceItemStateObject.GetItemEnvironmentDamage();				
			}

			if (WeaponTemplate != none)
			{
				PhysicalImpulseAmount = WeaponTemplate.iPhysicsImpulse;
				DamageTypeTemplateName = WeaponTemplate.DamageTypeTemplateName;
			}
			else
			{
				PhysicalImpulseAmount = 0;

				if( EffectDamageValue.DamageType != '' )
				{
					// If the damage effect's damage type is filled out, use that
					DamageTypeTemplateName = EffectDamageValue.DamageType;
				}
				else if( DamageTypes.Length > 0 )
				{
					// If there is at least one DamageType, use the first one (may want to change
					// in the future to make a more intelligent decision)
					DamageTypeTemplateName = DamageTypes[0];
				}
				else
				{
					// Default to explosive
					DamageTypeTemplateName = 'Explosion';
				}
			}
			
			// Issue #200 Start, allow listeners to modify environment damage
			ModifyEnvironmentDamageTuple = new class'XComLWTuple';
			ModifyEnvironmentDamageTuple.Id = 'ModifyEnvironmentDamage';
			ModifyEnvironmentDamageTuple.Data.Add(3);
			ModifyEnvironmentDamageTuple.Data[0].kind = XComLWTVBool;
			ModifyEnvironmentDamageTuple.Data[0].b = false;  // override? (true) or add? (false)
			ModifyEnvironmentDamageTuple.Data[1].kind = XComLWTVInt;
			ModifyEnvironmentDamageTuple.Data[1].i = 0;  // override/bonus environment damage
			ModifyEnvironmentDamageTuple.Data[2].kind = XComLWTVObject;
			ModifyEnvironmentDamageTuple.Data[2].o = AbilityStateObject;  // ability being used

			`XEVENTMGR.TriggerEvent('ModifyEnvironmentDamage', ModifyEnvironmentDamageTuple, self, NewGameState);
			
			if(ModifyEnvironmentDamageTuple.Data[0].b)
			{
				DamageAmount = ModifyEnvironmentDamageTuple.Data[1].i;
			}
			else
			{
				DamageAmount += ModifyEnvironmentDamageTuple.Data[1].i;
			}

			// Issue #200 End

			if( bLinearDamage && DamageAmount > 0 )
			{
				DamageEvent = XComGameState_EnvironmentDamage(NewGameState.CreateNewStateObject(class'XComGameState_EnvironmentDamage'));	
				DamageEvent.DEBUG_SourceCodeLocation    = "UC: X2Effect_ApplyWeaponDamage_Line:ApplyEffectToWorld";
				DamageEvent.DamageAmount                = DamageAmount;
				DamageEvent.DamageTypeTemplateName      = DamageTypeTemplateName;
				DamageEvent.HitLocation                 = ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
				DamageEvent.Momentum                    = DamageDirection;
				DamageEvent.PhysImpulse                 = PhysicalImpulseAmount;
				DamageEvent.DamageCause                 = SourceStateObject.GetReference();
				DamageEvent.DamageSource                = DamageEvent.DamageCause;
				DamageEvent.bRadialDamage               = false;
				DamageEvent.DamageTiles 				= AbilityContext.ResultContext.RelevantEffectTiles;
				DamageEvent.bAffectFragileOnly 			= false;

	            `LOG("[" $ GetFuncName() $ "] Generated Damage Event ObjectID: " $ DamageEvent.ObjectID $ " for location (" $ HitLocation.X $ ", " $ HitLocation.Y $ ", " $ HitLocation.Z $ ")",,'WotC_Gameplay_SupportStrikes');
			}
		}
	}
}

