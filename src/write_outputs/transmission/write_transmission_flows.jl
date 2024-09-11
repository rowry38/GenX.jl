function write_transmission_flows(path::AbstractString,
        inputs::Dict,
        setup::Dict,
        EP::Model)
    # Transmission related values
    T = inputs["T"]     # Number of time steps (hours)
    L = inputs["L"]     # Number of transmission lines
    # Power flows on transmission lines at each time step
    dfFlow = DataFrame(Line = 1:L)
    flow = value.(EP[:vFLOW])
    if setup["ParameterScale"] == 1
        flow *= ModelScalingFactor
    end

    filepath = joinpath(path, setup["WriteResultsNamesDict"]["flow"])
    if setup["WriteOutputs"] == "annual"
        dfFlow.AnnualSum = flow * inputs["omega"]
        total = DataFrame(["Total" sum(dfFlow.AnnualSum)], [:Line, :AnnualSum])
        dfFlow = vcat(dfFlow, total)
        write_output_file(filepath,
            dfFlow,
            filetype = setup["ResultsFileType"],
            compression = setup["ResultsCompressionType"])
    else # setup["WriteOutputs"] == "full" 
        dfFlow = hcat(dfFlow, DataFrame(flow, :auto))
        auxNew_Names = [Symbol("Line"); [Symbol("t$t") for t in 1:T]]
        rename!(dfFlow, auxNew_Names)

        write_output_file(filepath,
            dftranspose(dfFlow, true),
            filetype = setup["ResultsFileType"],
            compression = setup["ResultsCompressionType"])

        if setup["OutputFullTimeSeries"] == 1 && setup["TimeDomainReduction"] == 1
            write_full_time_series_reconstruction(path, setup,  dftranspose(dfFlow, true), setup["WriteResultsNamesDict"]["flow"])
            @info("Writing Full Time Series for Transmission Flows")
        end
    end
    return nothing
end
