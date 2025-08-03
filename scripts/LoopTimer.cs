using Godot;
using System;

public partial class LoopTimer : Timer
{
	[Export]
	public Node2D[] Freezables;

	[Export]
	public float DuplicateOpacity = 0.5f; // Adjustable opacity for duplicates

	private Transform2D[] _originalPositions;
	private Node2D[] _duplicates;

	public override void _Ready()
	{
		_duplicates = new Node2D[Freezables.Length];
		_originalPositions = new Transform2D[Freezables.Length];
		for (int i = 0; i < Freezables.Length; i++)
		{
			_originalPositions[i] = Freezables[i].GlobalTransform;
		}
	}

	public void OnTimeout()
	{
		for (int i = 0; i < Freezables.Length; i++)
		{
			_duplicates[i]?.QueueFree();
			_duplicates[i] = Freezables[i].Duplicate() as Node2D;

			// Set to process when paused, then pause the node
			_duplicates[i].ProcessMode = ProcessModeEnum.WhenPaused;
			_duplicates[i].SetProcess(false);
			_duplicates[i].SetPhysicsProcess(false);

			// Reduce opacity of all sprites in the duplicate
			SetOpacityRecursive(_duplicates[i], DuplicateOpacity);

			AddChild(_duplicates[i]);
			Freezables[i].GlobalTransform = _originalPositions[i];
		}
	}

	private static void SetOpacityRecursive(Node node, float opacity)
	{
		// Check if the node has a modulate property (Sprite2D, AnimatedSprite2D, etc.)
		if (node is CanvasItem canvasItem)
		{
			Color currentColor = canvasItem.Modulate;
			canvasItem.Modulate = new Color(currentColor.R, currentColor.G, currentColor.B, opacity);
		}

		// Recursively apply to all children
		foreach (Node child in node.GetChildren())
		{
			SetOpacityRecursive(child, opacity);
		}
	}
}
