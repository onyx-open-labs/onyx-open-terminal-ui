using System.Reflection;
using Onyx.OpenTerminal.UI;

namespace Onyx.OpenTerminal.UI.Tests;

public sealed class ScaffoldTests
{
    [Fact]
    public void ProductionAssemblyDoesNotReferenceTestFrameworks()
    {
        var assembly = typeof(AssemblyMarker).Assembly;
        var references = assembly.GetReferencedAssemblies();

        Assert.DoesNotContain(references, reference =>
            reference.Name is not null &&
            (reference.Name.StartsWith("xunit", StringComparison.OrdinalIgnoreCase) ||
             reference.Name.StartsWith("Microsoft.TestPlatform", StringComparison.OrdinalIgnoreCase) ||
             reference.Name.EndsWith(".Tests", StringComparison.Ordinal)));
    }
}
