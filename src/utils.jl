function get_file_paths(path::String)

    !isdir(joinpath(".", path)) && return [format_path(normpath(path))]

    file_paths = String[]
    for (root, dirs, files) in walkdir(joinpath(".", path))
        for dir in dirs
            get_file_paths(joinpath(root, dir), file_paths)
        end
        for file in files
            push!(file_paths, normpath(root, file))
        end
    end
    return [format_path(file_path) for file_path in file_paths]
end

function get_file_paths(path::String, file_paths::Vector{String})

    for (root, dirs, files) in walkdir(joinpath(".", path))
        for dir in dirs
            get_file_paths(joinpath(root, dir), file_paths)
        end
        for file in files
            push!(file_paths, normpath(root, file))
        end
    end
end

function format_path(path::String)

    return replace(path, "\\" => "/")
end
